from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from marcano.infrastructure.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    full_name: Mapped[str] = mapped_column(String(150))
    cedula: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    sku: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    name: Mapped[str] = mapped_column(Text)
    category: Mapped[str] = mapped_column(String(100), default="Otros / General", index=True)
    model: Mapped[str | None] = mapped_column(String(120))
    stock: Mapped[int] = mapped_column(default=0)
    min_stock: Mapped[int] = mapped_column(default=0)
    point: Mapped[int] = mapped_column(default=0)
    unit: Mapped[str] = mapped_column(String(20), default="UNI")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    unit_cost: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0.00"))
    sale_price: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0.00"))
    updated_by_user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
    )
    updated_by_user_name: Mapped[str | None] = mapped_column(String(150), nullable=True)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    updated_by_user: Mapped["User | None"] = relationship("User", foreign_keys=[updated_by_user_id])

    sales: Mapped[list["Sale"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    purchases: Mapped[list["Purchase"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    movements: Mapped[list["InventoryMovement"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )


class InventoryMovement(Base):
    __tablename__ = "inventory_movements"
    __table_args__ = (
        UniqueConstraint("source_file", "source_row", name="uq_inventory_movement_source"),
        Index(
            "ix_inventory_movement_product_operation_date",
            "product_id",
            "operation_type",
            "occurred_at",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    occurred_at: Mapped[datetime] = mapped_column(DateTime)
    operation_type: Mapped[str] = mapped_column(String(20))
    document_number: Mapped[int] = mapped_column(BigInteger)
    document_line: Mapped[int]
    user_code: Mapped[str | None] = mapped_column(String(50))
    counterparty: Mapped[str | None] = mapped_column(String(180))
    warehouse: Mapped[str] = mapped_column(String(30))
    unit: Mapped[str] = mapped_column(String(20))
    entries: Mapped[Decimal] = mapped_column(Numeric(18, 4), default=Decimal("0"))
    exits: Mapped[Decimal] = mapped_column(Numeric(18, 4), default=Decimal("0"))
    unit_cost: Mapped[Decimal] = mapped_column(Numeric(18, 4), default=Decimal("0"))
    source_file: Mapped[str] = mapped_column(String(255))
    source_row: Mapped[int]

    product: Mapped[Product] = relationship(back_populates="movements")


class Sale(Base):
    __tablename__ = "sales"

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    quantity: Mapped[int]
    unit_price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    sold_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)

    product: Mapped[Product] = relationship(back_populates="sales")


class Purchase(Base):
    __tablename__ = "purchases"

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    quantity: Mapped[int]
    unit_cost: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    purchased_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)

    product: Mapped[Product] = relationship(back_populates="purchases")


class DollarRate(Base):
    """Tasa del dolar configurada en el aplicativo (BCV o manual)."""

    __tablename__ = "dollar_rates"

    id: Mapped[int] = mapped_column(primary_key=True)
    value: Mapped[Decimal] = mapped_column(Numeric(18, 4))
    source: Mapped[str] = mapped_column(String(20), default="BCV")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, index=True
    )


class AlternateCurrency(Base):
    """Moneda alterna del sistema, con su tasa (BCV o manual)."""

    __tablename__ = "alternate_currencies"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    value: Mapped[Decimal] = mapped_column(Numeric(18, 4))
    source: Mapped[str] = mapped_column(String(20), default="BCV")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, index=True
    )
