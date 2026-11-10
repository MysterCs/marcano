from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuracion cargada desde variables de entorno o un archivo .env."""

    app_name: str = "Marcano Inventario"
    database_url: str = "sqlite:///./data/marcano.db"
    default_currency: str = "USD"
    locale: str = "es_ES"
    jwt_secret_key: str = "marcano-development-secret-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expiration_minutes: int = 480

    model_config = SettingsConfigDict(
        env_prefix="MARCANO_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
