from pathlib import Path

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import Engine
from sqlalchemy.engine.url import make_url
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    pass


PRODUCT_MIGRATION_COLUMNS: dict[str, str] = {
    "updated_by_user_id": "INTEGER",
    "updated_by_user_name": "VARCHAR(150)",
    "updated_at": "TIMESTAMP",
}


class Database:
    def __init__(self, url: str) -> None:
        self.url = make_url(url)
        self._ensure_sqlite_directory()
        connect_args = {"check_same_thread": False} if self.url.drivername == "sqlite" else {}
        self.engine: Engine = create_engine(self.url, connect_args=connect_args)
        self.session_factory = sessionmaker(
            bind=self.engine,
            class_=Session,
            expire_on_commit=False,
        )

    def _ensure_sqlite_directory(self) -> None:
        if self.url.drivername != "sqlite" or not self.url.database:
            return
        if self.url.database == ":memory:":
            return
        Path(self.url.database).expanduser().resolve().parent.mkdir(parents=True, exist_ok=True)

    def create_schema(self) -> None:
        # El import registra las tablas en los metadatos antes de crear el esquema.
        import marcano.infrastructure.models  # noqa: F401

        Base.metadata.create_all(self.engine)
        self._run_light_migrations()

    def _run_light_migrations(self) -> None:
        """Agrega columnas nuevas a tablas creadas con versiones anteriores."""
        inspector = inspect(self.engine)
        if "products" not in inspector.get_table_names():
            return
        existing = {column["name"] for column in inspector.get_columns("products")}
        with self.engine.begin() as connection:
            for name, column_type in PRODUCT_MIGRATION_COLUMNS.items():
                if name not in existing:
                    connection.execute(
                        text(f"ALTER TABLE products ADD COLUMN {name} {column_type}")
                    )
