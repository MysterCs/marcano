from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, sessionmaker

from marcano.domain.exceptions import DuplicateCedulaError
from marcano.infrastructure.models import User
from marcano.repositories.auth_base import AuthRepository


class SQLAlchemyAuthRepository(AuthRepository):
    def __init__(self, session_factory: sessionmaker[Session]) -> None:
        self._session_factory = session_factory

    def create_user(self, full_name: str, cedula: str, password_hash: str) -> User:
        try:
            with self._session_factory() as session, session.begin():
                user = User(
                    full_name=full_name,
                    cedula=cedula,
                    password_hash=password_hash,
                )
                session.add(user)
                session.flush()
                session.refresh(user)
                return user
        except IntegrityError as exc:
            raise DuplicateCedulaError(f"La cedula '{cedula}' ya esta registrada.") from exc

    def get_by_cedula(self, cedula: str) -> User | None:
        with self._session_factory() as session:
            return session.scalar(select(User).where(User.cedula == cedula))

    def get_by_id(self, user_id: int) -> User | None:
        with self._session_factory() as session:
            return session.get(User, user_id)
