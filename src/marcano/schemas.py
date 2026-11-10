from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from marcano.domain.entities import MovementType


class ProductCreate(BaseModel):
    sku: str = Field(min_length=1, max_length=50)
    name: str = Field(min_length=1, max_length=255)
    category: str | None = Field(default=None, max_length=100)
    initial_stock: int = Field(default=0, ge=0)
    min_stock: int = Field(default=0, ge=0)
    unit_cost: Decimal = Field(default=Decimal("0.00"), ge=0)
    sale_price: Decimal = Field(default=Decimal("0.00"), ge=0)

    @field_validator("sku", "name")
    @classmethod
    def strip_required_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("No puede estar vacio ni contener solo espacios.")
        return value


class ProductRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sku: str
    name: str
    category: str = "Otros / General"
    model: str | None
    stock: int
    min_stock: int
    point: int
    unit: str
    is_active: bool
    unit_cost: float
    sale_price: float
    updated_by_user_name: str | None = None
    updated_by_user_id: int | None = None
    updated_at: datetime | None = None


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    category: str | None = Field(default=None, min_length=1, max_length=100)
    model: str | None = Field(default=None, max_length=120)
    stock: int | None = Field(default=None, ge=0)
    min_stock: int | None = Field(default=None, ge=0)
    point: int | None = Field(default=None, ge=0)
    unit: str | None = Field(default=None, min_length=1, max_length=20)
    is_active: bool | None = None
    unit_cost: Decimal | None = Field(default=None, ge=0)
    sale_price: Decimal | None = Field(default=None, ge=0)

    @field_validator("name", "category", "model", "unit")
    @classmethod
    def strip_required_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("No puede estar vacio ni contener solo espacios.")
        return value

    def to_changes(self) -> dict[str, object]:
        data = self.model_dump(exclude_unset=True)
        if not data:
            raise ValueError("No hay cambios para guardar.")
        return data


class SaleCreate(BaseModel):
    quantity: int = Field(gt=0)
    unit_price: Decimal | None = Field(default=None, ge=0)


class PurchaseCreate(BaseModel):
    quantity: int = Field(gt=0)
    unit_cost: Decimal | None = Field(default=None, ge=0)


class InventorySummaryRead(BaseModel):
    products: int
    units: int
    low_stock: int
    inventory_value: float


class ProjectionPointRead(BaseModel):
    period: date
    quantity: float
    movement: MovementType


class HealthRead(BaseModel):
    status: str
    service: str


class UserCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=150)
    cedula: str = Field(min_length=1, max_length=30)
    password: str = Field(min_length=3, max_length=128)

    @field_validator("full_name", "cedula")
    @classmethod
    def strip_required_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("No puede estar vacio ni contener solo espacios.")
        return value


class LoginRequest(BaseModel):
    cedula: str = Field(min_length=1, max_length=30)
    password: str = Field(min_length=3, max_length=128)

    @field_validator("cedula")
    @classmethod
    def strip_cedula(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("La cedula es obligatoria.")
        return value


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    cedula: str


class TokenRead(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead


class DollarRateRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    value: float | None = None
    source: str | None = None
    updated_at: datetime | None = None


class ManualRateCreate(BaseModel):
    value: Decimal = Field(ge=0)


class BcvCurrencyRead(BaseModel):
    name: str
    value: float


class AlternateCurrencyCreate(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    value: Decimal | None = Field(default=None, ge=0)
    source: str = "bcv"

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("El nombre no puede estar vacio.")
        return value


class AlternateCurrencyRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    value: float
    source: str
    updated_at: datetime


class AlternateCurrencyValueUpdate(BaseModel):
    value: Decimal = Field(ge=0)


class MetricDistributionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    mean: float
    median: float
    mode: float
    std_dev: float
    variance: float
    minimum: float
    maximum: float
    p25: float
    p75: float
    p90: float
    iqr: float
    cv: float


class StockHealthSummaryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    optimal_count: int
    low_stock_count: int
    out_of_stock_count: int
    inactive_count: int


class CategoryStatRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    category: str
    product_count: int
    total_units: int
    total_value: float
    share_percentage: float
    low_stock_count: int
    avg_stock: float
    avg_unit_cost: float


class TopProductStatRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sku: str
    name: str
    category: str
    stock: int
    unit_cost: float
    total_value: float


class MonthlyRotationPointRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    period: str
    entries: float
    exits: float


class DescriptiveStatisticsRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    total_products: int
    total_units: int
    total_inventory_value: float
    active_categories: int
    stock_distribution: MetricDistributionRead
    cost_distribution: MetricDistributionRead
    value_distribution: MetricDistributionRead
    stock_health: StockHealthSummaryRead
    categories: list[CategoryStatRead]
    top_by_value: list[TopProductStatRead]
    top_by_stock: list[TopProductStatRead]
    monthly_rotation: list[MonthlyRotationPointRead]


class ReclassifyResultRead(BaseModel):
    updated: int
