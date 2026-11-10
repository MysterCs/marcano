from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from enum import Enum


class MovementType(str, Enum):
    SALE = "sale"
    PURCHASE = "purchase"


@dataclass(frozen=True, slots=True)
class MovementRecord:
    occurred_at: datetime
    quantity: int


@dataclass(frozen=True, slots=True)
class ProjectionPoint:
    period: date
    quantity: float
    movement: MovementType


@dataclass(frozen=True, slots=True)
class InventorySummary:
    products: int
    units: int
    low_stock: int
    inventory_value: Decimal
