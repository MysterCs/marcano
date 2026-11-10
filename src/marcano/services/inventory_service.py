from decimal import Decimal

from marcano.domain.entities import InventorySummary
from marcano.infrastructure.models import Product
from marcano.repositories.base import InventoryRepository


class InventoryService:
    def __init__(self, repository: InventoryRepository) -> None:
        self._repository = repository

    def list_products(self) -> list[Product]:
        return self._repository.list_products()

    def create_product(
        self,
        sku: str,
        name: str,
        initial_stock: int = 0,
        min_stock: int = 0,
        unit_cost: Decimal = Decimal("0.00"),
        sale_price: Decimal = Decimal("0.00"),
    ) -> Product:
        if not sku.strip() or not name.strip():
            raise ValueError("El SKU y el nombre son obligatorios.")
        if initial_stock < 0 or min_stock < 0:
            raise ValueError("Las existencias no pueden ser negativas.")
        if unit_cost < 0 or sale_price < 0:
            raise ValueError("Los precios no pueden ser negativos.")
        return self._repository.create_product(
            sku.strip(), name.strip(), initial_stock, min_stock, unit_cost, sale_price
        )

    def register_sale(
        self, product_id: int, quantity: int, unit_price: Decimal | None = None
    ) -> Product:
        if quantity <= 0:
            raise ValueError("La cantidad vendida debe ser mayor que cero.")
        return self._repository.register_sale(product_id, quantity, unit_price)

    def register_purchase(
        self, product_id: int, quantity: int, unit_cost: Decimal | None = None
    ) -> Product:
        if quantity <= 0:
            raise ValueError("La cantidad comprada debe ser mayor que cero.")
        if unit_cost is not None and unit_cost < 0:
            raise ValueError("El coste no puede ser negativo.")
        return self._repository.register_purchase(product_id, quantity, unit_cost)

    def update_product(
        self,
        product_id: int,
        changes: dict[str, object],
        updated_by_user_id: int | None = None,
        updated_by_user_name: str | None = None,
    ) -> Product:
        if not changes:
            raise ValueError("No hay cambios para guardar.")
        if changes.get("name") is not None and not str(changes["name"]).strip():
            raise ValueError("El nombre no puede estar vacio.")
        if "stock" in changes and int(changes["stock"]) < 0:  # type: ignore[arg-type]
            raise ValueError("Las existencias no pueden ser negativas.")
        if "min_stock" in changes and int(changes["min_stock"]) < 0:  # type: ignore[arg-type]
            raise ValueError("El stock minimo no puede ser negativo.")
        if "point" in changes and int(changes["point"]) < 0:  # type: ignore[arg-type]
            raise ValueError("El punto no puede ser negativo.")
        if "unit_cost" in changes and Decimal(str(changes["unit_cost"])) < 0:
            raise ValueError("El coste no puede ser negativo.")
        if "sale_price" in changes and Decimal(str(changes["sale_price"])) < 0:
            raise ValueError("El precio de venta no puede ser negativo.")
        return self._repository.update_product(
            product_id, changes, updated_by_user_id, updated_by_user_name
        )

    def summary(self) -> InventorySummary:
        products = self._repository.list_products()
        return InventorySummary(
            products=len(products),
            units=sum(product.stock for product in products),
            low_stock=sum(product.stock <= product.min_stock for product in products),
            inventory_value=sum(
                (product.unit_cost * product.stock for product in products),
                start=Decimal("0.00"),
            ),
        )
