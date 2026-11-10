from datetime import datetime

from openpyxl import Workbook
from sqlalchemy import func, select

from marcano.infrastructure.database import Database
from marcano.infrastructure.excel_import import ExcelImporter
from marcano.infrastructure.models import InventoryMovement, Product
from marcano.repositories.sqlalchemy import SQLAlchemyInventoryRepository


def test_excel_import_is_complete_and_idempotent(tmp_path):
    inventory_path = tmp_path / "inventory.xlsx"
    workbook = Workbook()
    sheet = workbook.active
    for _ in range(6):
        sheet.append([None] * 6)
    sheet.append(["CURRENT", "Model", "Producto actual", 0, 10, "UNI"])
    sheet.append(["CODIGO", "MODELO", "DESCRIPCION", "PUNTO", "STOCK ACTUAL", "UNIDAD"])
    workbook.save(inventory_path)

    rotation_path = tmp_path / "rotation.xlsx"
    workbook = Workbook()
    sheet = workbook.active
    for _ in range(7):
        sheet.append([None] * 14)
    sheet.append(
        [
            datetime(2026, 1, 1),
            "CURRENT",
            "Model",
            "Producto actual",
            "NENT",
            100,
            1,
            "U",
            "Cliente",
            1,
            "UNI",
            0,
            -2,
            12.5,
        ]
    )
    sheet.append(
        [
            datetime(2026, 1, 2),
            "HIST",
            "Old",
            "Producto historico",
            "NREC",
            101,
            1,
            "U",
            "Proveedor",
            1,
            "UNI",
            5,
            0,
            4,
        ]
    )
    sheet.append(["Subtotales:"] + [None] * 13)
    workbook.save(rotation_path)

    database = Database(f"sqlite:///{tmp_path / 'import.db'}")
    database.create_schema()
    importer = ExcelImporter(database.session_factory)
    result = importer.import_files(inventory_path, rotation_path)

    assert result.current_products == 1
    assert result.historical_products == 1
    assert result.movements_inserted == 2
    assert result.movements_skipped == 0

    with database.session_factory() as session:
        products = {product.sku: product for product in session.scalars(select(Product)).all()}
        assert products["CURRENT"].stock == 10
        assert products["CURRENT"].is_active is True
        assert float(products["CURRENT"].unit_cost) == 12.5
        assert products["HIST"].stock == 0
        assert products["HIST"].is_active is False
        assert session.scalar(select(func.count(InventoryMovement.id))) == 2

    repository = SQLAlchemyInventoryRepository(database.session_factory)
    assert repository.sales_history(products["CURRENT"].id)[0].quantity == 2
    assert repository.purchases_history(products["HIST"].id)[0].quantity == 5

    repeated = importer.import_files(inventory_path, rotation_path)
    assert repeated.movements_inserted == 0
    assert repeated.movements_skipped == 2
