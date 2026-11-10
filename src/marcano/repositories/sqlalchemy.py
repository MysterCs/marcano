from datetime import datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, sessionmaker

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
    ) -> Product:
        try:
            with self._session_factory() as session, session.begin():
                product = Product(
                    sku=sku,
                    name=name,
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

    @staticmethod
    def _locked_product(session: Session, product_id: int) -> Product:
        product = session.get(Product, product_id)
        if product is None:
            raise ProductNotFoundError(f"No existe el producto {product_id}.")
        return product
