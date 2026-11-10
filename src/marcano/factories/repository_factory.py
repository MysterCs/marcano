from sqlalchemy.engine.url import make_url

from marcano.config import Settings, get_settings
from marcano.infrastructure.database import Database
from marcano.repositories.auth_base import AuthRepository
from marcano.repositories.base import InventoryRepository
from marcano.repositories.sqlalchemy import SQLAlchemyInventoryRepository
from marcano.repositories.sqlalchemy_auth import SQLAlchemyAuthRepository
from marcano.repositories.sqlalchemy_currency import SQLAlchemyCurrencyRateRepository
from marcano.repositories.sqlalchemy_rate import SQLAlchemyRateRepository


class RepositoryFactory:
    """Crea el repositorio adecuado para la URL de base de datos configurada."""

    @classmethod
    def create(cls, settings: Settings | None = None) -> InventoryRepository:
        database = cls._create_database(settings or get_settings())
        return SQLAlchemyInventoryRepository(database.session_factory)

    @classmethod
    def create_auth(cls, settings: Settings | None = None) -> AuthRepository:
        database = cls._create_database(settings or get_settings())
        return SQLAlchemyAuthRepository(database.session_factory)

    @classmethod
    def create_rate(cls, settings: Settings | None = None):
        database = cls._create_database(settings or get_settings())
        return SQLAlchemyRateRepository(database.session_factory)

    @classmethod
    def create_currency(cls, settings: Settings | None = None):
        database = cls._create_database(settings or get_settings())
        return SQLAlchemyCurrencyRateRepository(database.session_factory)

    @staticmethod
    def _create_database(settings: Settings) -> Database:
        driver = make_url(settings.database_url).drivername
        if driver not in {"sqlite", "postgresql+psycopg"}:
            raise ValueError(
                f"El motor '{driver}' todavia no tiene un repositorio registrado. "
                "Use SQLite o PostgreSQL con psycopg."
            )
        database = Database(settings.database_url)
        database.create_schema()
        return database
