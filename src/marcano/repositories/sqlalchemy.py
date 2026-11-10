from datetime import datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, sessionmaker

from marcano.domain.categories import infer_category
from marcano.domain.entities import MovementRecord
from marcano.domain.exceptions import (
    DuplicateSKUError,
    InsufficientStockError,
    ProductNotFoundError,
)
from marcano.infrastructure.models import InventoryMovement, Product, Purchase, Sale
from marcano.repositories.base import InventoryRepository


class SQLAlchemyInventoryRepository(InventoryRepository):
    def __init__(self, session_factory: sessionmaker[Session]) -> None:
        self._session_factory = session_factory

    def list_products(self) -> list[Product]:
        with self._session_factory() as session:
            return list(session.scalars(select(Product).order_by(Product.name)).all())

    def get_product(self, product_id: int) -> Product:
        with self._session_factory() as session:
            product = session.get(Product, product_id)
            if product is None:
                raise ProductNotFoundError(f"No existe el producto {product_id}.")
            return product

    def create_product(
        self,
        sku: str,
        name: str,
        initial_stock: int,
        min_stock: int,
        unit_cost: Decimal,
        sale_price: Decimal,
        category: str | None = None,
    ) -> Product:
        resolved_category = (category or "").strip() or infer_category(name)
        try:
            with self._session_factory() as session, session.begin():
                product = Product(
                    sku=sku,
                    name=name,
                    category=resolved_category,
                    stock=initial_stock,
                    min_stock=min_stock,
                    unit_cost=unit_cost,
                    sale_price=sale_price,
                )
                session.add(product)
                session.flush()
                session.refresh(product)
                return product
        except IntegrityError as exc:
            raise DuplicateSKUError(f"El SKU '{sku}' ya esta registrado.") from exc

    def register_sale(
        self, product_id: int, quantity: int, unit_price: Decimal | None = None
    ) -> Product:
        with self._session_factory() as session, session.begin():
            product = self._locked_product(session, product_id)
            if product.stock < quantity:
                raise InsufficientStockError(
                    f"Stock insuficiente: disponible {product.stock}, solicitado {quantity}."
                )
            product.stock -= quantity
            session.add(
                Sale(
                    product=product,
                    quantity=quantity,
                    unit_price=unit_price if unit_price is not None else product.sale_price,
                )
            )
            session.flush()
            session.refresh(product)
            return product

    def register_purchase(
        self, product_id: int, quantity: int, unit_cost: Decimal | None = None
    ) -> Product:
        with self._session_factory() as session, session.begin():
            product = self._locked_product(session, product_id)
            product.stock += quantity
            product.unit_cost = unit_cost if unit_cost is not None else product.unit_cost
            session.add(
                Purchase(
                    product=product,
                    quantity=quantity,
                    unit_cost=product.unit_cost,
                )
            )
            session.flush()
            session.refresh(product)
            return product

    def update_product(
        self,
        product_id: int,
        changes: dict[str, object],
        updated_by_user_id: int | None = None,
        updated_by_user_name: str | None = None,
    ) -> Product:
        with self._session_factory() as session, session.begin():
            product = self._locked_product(session, product_id)
            if "name" in changes and "category" not in changes:
                changes = dict(changes)
                changes["category"] = infer_category(str(changes["name"]))
            for field, value in changes.items():
                setattr(product, field, value)
            product.updated_by_user_id = updated_by_user_id
            product.updated_by_user_name = updated_by_user_name
            product.updated_at = datetime.utcnow()
            session.flush()
            session.refresh(product)
            return product

    def sales_history(self, product_id: int) -> list[MovementRecord]:
        with self._session_factory() as session:
            rows = session.execute(
                select(Sale.sold_at, Sale.quantity).where(Sale.product_id == product_id)
            ).all()
            imported_rows = session.execute(
                select(InventoryMovement.occurred_at, InventoryMovement.exits).where(
                    InventoryMovement.product_id == product_id,
                    InventoryMovement.operation_type.in_(("NENT", "FACT")),
                )
            ).all()
            history = [MovementRecord(occurred_at=row[0], quantity=row[1]) for row in rows]
            history.extend(
                MovementRecord(occurred_at=row[0], quantity=int(abs(row[1])))
                for row in imported_rows
            )
            return sorted(history, key=lambda item: item.occurred_at)

    def purchases_history(self, product_id: int) -> list[MovementRecord]:
        with self._session_factory() as session:
            rows = session.execute(
                select(Purchase.purchased_at, Purchase.quantity).where(
                    Purchase.product_id == product_id
                )
            ).all()
            imported_rows = session.execute(
                select(InventoryMovement.occurred_at, InventoryMovement.entries).where(
                    InventoryMovement.product_id == product_id,
                    InventoryMovement.operation_type.in_(("NREC", "COMP")),
                )
            ).all()
            history = [MovementRecord(occurred_at=row[0], quantity=row[1]) for row in rows]
            history.extend(
                MovementRecord(occurred_at=row[0], quantity=int(abs(row[1])))
                for row in imported_rows
            )
            return sorted(history, key=lambda item: item.occurred_at)

    def reclassify_categories(self) -> int:
        with self._session_factory() as session, session.begin():
            products = session.scalars(select(Product)).all()
            updated = 0
            for product in products:
                inferred = infer_category(product.name)
                if product.category != inferred:
                    product.category = inferred
                    updated += 1
            return updated

    def monthly_rotation_summary(self) -> list[tuple[str, float, float]]:
        with self._session_factory() as session:
            movements = session.execute(
                select(
                    InventoryMovement.occurred_at,
                    InventoryMovement.entries,
                    InventoryMovement.exits,
                )
            ).all()
            sales = session.execute(select(Sale.sold_at, Sale.quantity)).all()
            purchases = session.execute(select(Purchase.purchased_at, Purchase.quantity)).all()

            buckets: dict[str, list[float]] = {}
            for occurred_at, entries, exits in movements:
                key = f"{occurred_at.year:04d}-{occurred_at.month:02d}"
                bucket = buckets.setdefault(key, [0.0, 0.0])
                bucket[0] += float(abs(entries or 0))
                bucket[1] += float(abs(exits or 0))
            for sold_at, qty in sales:
                key = f"{sold_at.year:04d}-{sold_at.month:02d}"
                bucket = buckets.setdefault(key, [0.0, 0.0])
                bucket[1] += float(abs(qty or 0))
            for purchased_at, qty in purchases:
                key = f"{purchased_at.year:04d}-{purchased_at.month:02d}"
                bucket = buckets.setdefault(key, [0.0, 0.0])
                bucket[0] += float(abs(qty or 0))

            return [
                (period, round(vals[0], 2), round(vals[1], 2))
                for period, vals in sorted(buckets.items())[-12:]
            ]

    @staticmethod
    def _locked_product(session: Session, product_id: int) -> Product:
        product = session.get(Product, product_id)
        if product is None:
            raise ProductNotFoundError(f"No existe el producto {product_id}.")
        return product
