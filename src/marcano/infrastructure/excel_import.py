from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from pathlib import Path

from openpyxl import load_workbook
from sqlalchemy import insert, select
from sqlalchemy.orm import Session, sessionmaker

from marcano.infrastructure.models import InventoryMovement, Product


@dataclass(frozen=True, slots=True)
class ImportResult:
    current_products: int
    historical_products: int
    movements_inserted: int
    movements_skipped: int


@dataclass(frozen=True, slots=True)
class _ProductRow:
    sku: str
    model: str | None
    name: str
    point: int
    stock: int
    unit: str


@dataclass(frozen=True, slots=True)
class _MovementRow:
    occurred_at: datetime
    sku: str
    model: str | None
    name: str
    operation_type: str
    document_number: int
    document_line: int
    user_code: str | None
    counterparty: str | None
    warehouse: str
    unit: str
    entries: Decimal
    exits: Decimal
    unit_cost: Decimal
    source_row: int


class ExcelImporter:
    """Importa los reportes Profit Plus sin subtotales ni cabeceras repetidas."""

    def __init__(self, session_factory: sessionmaker[Session]) -> None:
        self._session_factory = session_factory

    def import_files(self, inventory_path: Path, rotation_path: Path) -> ImportResult:
        inventory = self._read_inventory(inventory_path)
        movements = self._read_rotation(rotation_path)
        current_skus = {item.sku for item in inventory}
        historical_skus = {item.sku for item in movements} - current_skus
        latest_movements = self._latest_by_sku(movements)

        with self._session_factory() as session, session.begin():
            products = {product.sku: product for product in session.scalars(select(Product)).all()}

            for item in inventory:
                product = products.get(item.sku)
                if product is None:
                    product = Product(sku=item.sku, name=item.name)
                    session.add(product)
                    products[item.sku] = product
                product.model = item.model
                product.name = item.name
                product.point = item.point
                product.stock = item.stock
                product.unit = item.unit
                product.is_active = True

            for sku in historical_skus:
                latest = latest_movements[sku]
                product = products.get(sku)
                if product is None:
                    product = Product(sku=sku, name=latest.name)
                    session.add(product)
                    products[sku] = product
                product.model = latest.model
                product.name = latest.name
                product.stock = 0
                product.unit = latest.unit
                product.is_active = False

            for sku, latest in latest_movements.items():
                product = products[sku]
                if product.unit_cost is None or product.unit_cost == 0:
                    product.unit_cost = latest.unit_cost

            session.flush()
            existing_sources = set(
                session.execute(
                    select(InventoryMovement.source_file, InventoryMovement.source_row).where(
                        InventoryMovement.source_file == rotation_path.name
                    )
                ).all()
            )
            pending: list[dict[str, object]] = []
            skipped = 0
            for item in movements:
                source = (rotation_path.name, item.source_row)
                if source in existing_sources:
                    skipped += 1
                    continue
                pending.append(
                    {
                        "product_id": products[item.sku].id,
                        "occurred_at": item.occurred_at,
                        "operation_type": item.operation_type,
                        "document_number": item.document_number,
                        "document_line": item.document_line,
                        "user_code": item.user_code,
                        "counterparty": item.counterparty,
                        "warehouse": item.warehouse,
                        "unit": item.unit,
                        "entries": item.entries,
                        "exits": item.exits,
                        "unit_cost": item.unit_cost,
                        "source_file": rotation_path.name,
                        "source_row": item.source_row,
                    }
                )

            for start in range(0, len(pending), 500):
                session.execute(insert(InventoryMovement), pending[start : start + 500])

        return ImportResult(
            current_products=len(current_skus),
            historical_products=len(historical_skus),
            movements_inserted=len(pending),
            movements_skipped=skipped,
        )

    @staticmethod
    def _read_inventory(path: Path) -> list[_ProductRow]:
        workbook = load_workbook(path, data_only=True, read_only=True)
        sheet = workbook.worksheets[0]
        rows: list[_ProductRow] = []
        for values in sheet.iter_rows(min_row=7, values_only=True):
            sku = str(values[0]).strip() if values[0] is not None else ""
            name = str(values[2]).strip() if values[2] is not None else ""
            stock = values[4]
            if not sku or sku.upper() == "CODIGO" or not name:
                continue
            if not isinstance(stock, (int, float)):
                continue
            rows.append(
                _ProductRow(
                    sku=sku,
                    model=ExcelImporter._optional_text(values[1]),
                    name=name,
                    point=int(values[3] or 0),
                    stock=int(stock),
                    unit=str(values[5] or "UNI").strip(),
                )
            )
        workbook.close()
        return rows

    @staticmethod
    def _read_rotation(path: Path) -> list[_MovementRow]:
        workbook = load_workbook(path, data_only=True, read_only=True)
        sheet = workbook.worksheets[0]
        rows: list[_MovementRow] = []
        for source_row, values in enumerate(sheet.iter_rows(min_row=8, values_only=True), start=8):
            if not isinstance(values[0], datetime) or values[1] is None:
                continue
            rows.append(
                _MovementRow(
                    occurred_at=values[0],
                    sku=str(values[1]).strip(),
                    model=ExcelImporter._optional_text(values[2]),
                    name=str(values[3]).strip(),
                    operation_type=str(values[4]).strip(),
                    document_number=int(values[5]),
                    document_line=int(values[6]),
                    user_code=ExcelImporter._optional_text(values[7]),
                    counterparty=ExcelImporter._optional_text(values[8]),
                    warehouse=str(values[9]).strip(),
                    unit=str(values[10]).strip(),
                    entries=Decimal(str(values[11] or 0)),
                    exits=Decimal(str(values[12] or 0)),
                    unit_cost=Decimal(str(values[13] or 0)),
                    source_row=source_row,
                )
            )
        workbook.close()
        return rows

    @staticmethod
    def _latest_by_sku(movements: list[_MovementRow]) -> dict[str, _MovementRow]:
        latest: dict[str, _MovementRow] = {}
        for item in movements:
            current = latest.get(item.sku)
            if current is None or (item.occurred_at, item.source_row) > (
                current.occurred_at,
                current.source_row,
            ):
                latest[item.sku] = item
        return latest

    @staticmethod
    def _optional_text(value: object) -> str | None:
        if value is None:
            return None
        text = str(value).strip()
        return text or None
