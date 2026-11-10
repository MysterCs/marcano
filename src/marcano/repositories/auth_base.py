from abc import ABC, abstractmethod

from marcano.infrastructure.models import User


class AuthRepository(ABC):
    @abstractmethod
    def create_user(self, full_name: str, cedula: str, password_hash: str) -> User:
        raise NotImplementedError

    @abstractmethod
    def get_by_cedula(self, cedula: str) -> User | None:
        raise NotImplementedError

    @abstractmethod
    def get_by_id(self, user_id: int) -> User | None:
        raise NotImplementedError
