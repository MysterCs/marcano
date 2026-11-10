import argparse
import json
from dataclasses import asdict
from pathlib import Path

from marcano.config import get_settings
from marcano.infrastructure.database import Database
from marcano.infrastructure.excel_import import ExcelImporter


def main() -> None:
    parser = argparse.ArgumentParser(description="Importa inventario y rotacion desde Excel.")
    parser.add_argument("--inventory", type=Path, default=Path("data/INVENTARIO ACTUAL.xlsx"))
    parser.add_argument("--rotation", type=Path, default=Path("data/ROTACION DE INVENTARIO.xlsx"))
    parser.add_argument("--database-url", help="Sobrescribe MARCANO_DATABASE_URL.")
    args = parser.parse_args()

    database_url = args.database_url or get_settings().database_url
    database = Database(database_url)
    database.create_schema()
    result = ExcelImporter(database.session_factory).import_files(args.inventory, args.rotation)
    print(json.dumps(asdict(result), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
