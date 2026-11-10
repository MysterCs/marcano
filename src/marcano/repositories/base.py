from abc import ABC, abstractmethod
from decimal import Decimal

from marcano.domain.entities import MovementRecord
from marcano.infrastructure.models import Product


class InventoryRepository(ABC):
    @abstractmethod
    def list_products(self) -> list[Product]:
        raise NotImplementedError

    @abstractmethod
    def get_product(self, product_id: int) -> Product:
        raise NotImplementedError

    @abstractmethod
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
        raise NotImplementedError

    @abstractmethod
    def register_sale(
        self, product_id: int, quantity: int, unit_price: Decimal | None = None
    ) -> Product:
        raise NotImplementedError

    @abstractmethod
    def register_purchase(
        self, product_id: int, quantity: int, unit_cost: Decimal | None = None
    ) -> Product:
        raise NotImplementedError

    @abstractmethod
    def update_product(
        self,
        product_id: int,
        changes: dict[str, object],
        updated_by_user_id: int | None = None,
        updated_by_user_name: str | None = None,
    ) -> Product:
        raise NotImplementedError

    @abstractmethod
    def sales_history(self, product_id: int) -> list[MovementRecord]:
        raise NotImplementedError

    @abstractmethod
    def purchases_history(self, product_id: int) -> list[MovementRecord]:
        raise NotImplementedError

    def reclassify_categories(self) -> int:
        return 0

    def monthly_rotation_summary(self) -> list[tuple[str, float, float]]:
        return []
