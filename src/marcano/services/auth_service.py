from datetime import datetime, timedelta, timezone

import jwt
from jwt import InvalidTokenError
from pwdlib import PasswordHash

from marcano.config import Settings
from marcano.domain.exceptions import AuthenticationError, InvalidSessionError
from marcano.infrastructure.models import User
from marcano.repositories.auth_base import AuthRepository


class AuthService:
    def __init__(self, repository: AuthRepository, settings: Settings) -> None:
        self._repository = repository
        self._settings = settings
        self._password_hash = PasswordHash.recommended()

    def register(self, full_name: str, cedula: str, password: str) -> User:
        full_name = full_name.strip()
        cedula = cedula.strip()
        if not full_name or not cedula:
            raise ValueError("El nombre completo y la cedula son obligatorios.")
        if len(password) < 3:
            raise ValueError("La contrasena debe tener al menos 3 caracteres.")
        return self._repository.create_user(
            full_name=full_name,
            cedula=cedula,
            password_hash=self._password_hash.hash(password),
        )

    def authenticate(self, cedula: str, password: str) -> User:
        user = self._repository.get_by_cedula(cedula.strip())
        if (
            user is None
            or not user.is_active
            or not self._password_hash.verify(password, user.password_hash)
        ):
            raise AuthenticationError("Cedula o contrasena incorrecta.")
        return user

    def create_access_token(self, user: User) -> str:
        now = datetime.now(timezone.utc)
        payload = {
            "sub": str(user.id),
            "iat": now,
            "exp": now + timedelta(minutes=self._settings.jwt_expiration_minutes),
        }
        return jwt.encode(
            payload,
            self._settings.jwt_secret_key,
            algorithm=self._settings.jwt_algorithm,
        )

    def user_from_token(self, token: str) -> User:
        try:
            payload = jwt.decode(
                token,
                self._settings.jwt_secret_key,
                algorithms=[self._settings.jwt_algorithm],
            )
            user_id = int(payload["sub"])
        except (InvalidTokenError, KeyError, TypeError, ValueError) as exc:
            raise InvalidSessionError("La sesion no es valida o ha expirado.") from exc

        user = self._repository.get_by_id(user_id)
        if user is None or not user.is_active:
            raise InvalidSessionError("La sesion no es valida o ha expirado.")
        return user
