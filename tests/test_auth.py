import jwt
import pytest

from marcano.config import get_settings
from marcano.domain.exceptions import InvalidSessionError
from marcano.services.auth_service import AuthService


def test_register_hashes_password_and_login_returns_token(anonymous_client, auth_repository):
    response = anonymous_client.post(
        "/api/auth/register",
        json={"full_name": "Maria Perez", "cedula": "V-001", "password": "abc"},
    )

    assert response.status_code == 201
    assert response.json() == {"id": 1, "full_name": "Maria Perez", "cedula": "V-001"}
    assert "password" not in response.json()
    assert "password_hash" not in response.json()
    user = auth_repository.get_by_cedula("V-001")
    assert user is not None
    assert user.password_hash != "abc"

    login = anonymous_client.post(
        "/api/auth/login", json={"cedula": "V-001", "password": "abc"}
    )
    assert login.status_code == 200
    token = login.json()["access_token"]
    assert login.json()["token_type"] == "bearer"
    assert login.json()["user"]["full_name"] == "Maria Perez"

    me = anonymous_client.get(
        "/api/auth/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert me.status_code == 200
    assert me.json()["cedula"] == "V-001"


def test_registration_requires_three_password_characters(anonymous_client):
    response = anonymous_client.post(
        "/api/auth/register",
        json={"full_name": "Usuario", "cedula": "V-002", "password": "ab"},
    )
    assert response.status_code == 422


def test_duplicate_cedula_and_invalid_credentials_are_rejected(anonymous_client):
    user = {"full_name": "Usuario", "cedula": "V-003", "password": "123"}
    assert anonymous_client.post("/api/auth/register", json=user).status_code == 201
    assert anonymous_client.post("/api/auth/register", json=user).status_code == 409

    wrong_password = anonymous_client.post(
        "/api/auth/login", json={"cedula": "V-003", "password": "999"}
    )
    assert wrong_password.status_code == 401
    assert wrong_password.json()["detail"] == "Cedula o contrasena incorrecta."

    missing_user = anonymous_client.post(
        "/api/auth/login", json={"cedula": "V-999", "password": "123"}
    )
    assert missing_user.status_code == 401


def test_protected_endpoints_require_a_valid_token(anonymous_client):
    assert anonymous_client.get("/api/products").status_code == 401
    assert anonymous_client.get(
        "/api/products", headers={"Authorization": "Bearer invalid"}
    ).status_code == 401


def test_token_subject_must_identify_an_active_user(auth_repository):
    service = AuthService(auth_repository, get_settings())
    user = service.register("Usuario", "V-004", "123")
    token = jwt.encode(
        {"sub": str(user.id + 100)},
        get_settings().jwt_secret_key,
        algorithm=get_settings().jwt_algorithm,
    )

    with pytest.raises(InvalidSessionError, match="sesion"):
        service.user_from_token(token)
