from abc import ABC, abstractmethod
from datetime import datetime
from decimal import Decimal

from marcano.infrastructure.models import DollarRate


class RateRepository(ABC):
    @abstractmethod
    def get_current(self) -> DollarRate | None:
        raise NotImplementedError

    @abstractmethod
    def save(self, value: Decimal, source: str, updated_at: datetime) -> DollarRate:
        raise NotImplementedError
