import pytest
from fastapi.testclient import TestClient

from marcano.api import (
    create_app,
    get_auth_repository,
    get_currency_repository,
    get_rate_repository,
    get_repository,
)
from marcano.config import Settings
from marcano.factories.repository_factory import RepositoryFactory
from marcano.repositories.currency_base import CurrencyRateRepository


@pytest.fixture
def settings(tmp_path):
    return Settings(database_url=f"sqlite:///{tmp_path / 'test.db'}")


@pytest.fixture
def repository(settings):
    return RepositoryFactory.create(settings)


@pytest.fixture
def auth_repository(settings):
    return RepositoryFactory.create_auth(settings)


@pytest.fixture
def rate_repository(settings):
    return RepositoryFactory.create_rate(settings)


@pytest.fixture
def currency_repository(settings) -> CurrencyRateRepository:
    return RepositoryFactory.create_currency(settings)


@pytest.fixture
def anonymous_client(repository, auth_repository, rate_repository, currency_repository):
    app = create_app()
    app.dependency_overrides[get_repository] = lambda: repository
    app.dependency_overrides[get_auth_repository] = lambda: auth_repository
    app.dependency_overrides[get_rate_repository] = lambda: rate_repository
    app.dependency_overrides[get_currency_repository] = lambda: currency_repository
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def client(anonymous_client):
    registered = anonymous_client.post(
        "/api/auth/register",
        json={
            "full_name": "Usuario de Pruebas",
            "cedula": "TEST-001",
            "password": "123",
        },
    )
    assert registered.status_code == 201
    login = anonymous_client.post(
        "/api/auth/login",
        json={"cedula": "TEST-001", "password": "123"},
    )
    assert login.status_code == 200
    token = login.json()["access_token"]
    anonymous_client.headers["Authorization"] = f"Bearer {token}"
    return anonymous_client
