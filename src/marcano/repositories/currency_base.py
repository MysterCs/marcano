from abc import ABC, abstractmethod
from datetime import datetime
from decimal import Decimal

from marcano.infrastructure.models import AlternateCurrency


class CurrencyRateRepository(ABC):
    @abstractmethod
    def list_alternates(self) -> list[AlternateCurrency]:
        raise NotImplementedError

    @abstractmethod
    def replace_alternates(
        self, items: list[tuple[str, Decimal, str, datetime]]
    ) -> list[AlternateCurrency]:
        raise NotImplementedError

    @abstractmethod
    def update_value(self, currency_id: int, value: Decimal) -> AlternateCurrency | None:
        raise NotImplementedError

    @abstractmethod
    def delete(self, currency_id: int) -> bool:
        raise NotImplementedError
