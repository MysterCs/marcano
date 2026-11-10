from datetime import datetime
from decimal import Decimal

from sqlalchemy import delete, select
from sqlalchemy.orm import Session, sessionmaker

from marcano.domain.exceptions import ProductNotFoundError
from marcano.infrastructure.models import AlternateCurrency
from marcano.repositories.currency_base import CurrencyRateRepository


class SQLAlchemyCurrencyRateRepository(CurrencyRateRepository):
    def __init__(self, session_factory: sessionmaker[Session]) -> None:
        self._session_factory = session_factory

    def list_alternates(self) -> list[AlternateCurrency]:
        with self._session_factory() as session:
            return list(
                session.scalars(
                    select(AlternateCurrency).order_by(AlternateCurrency.id)
                ).all()
            )

    def replace_alternates(
        self, items: list[tuple[str, Decimal, str, datetime]]
    ) -> list[AlternateCurrency]:
        with self._session_factory() as session, session.begin():
            session.execute(delete(AlternateCurrency))
            created = [
                AlternateCurrency(name=name, value=value, source=source, updated_at=stamp)
                for name, value, source, stamp in items
            ]
            session.add_all(created)
            session.flush()
            return list(
                session.scalars(
                    select(AlternateCurrency).order_by(AlternateCurrency.id)
                ).all()
            )

    def update_value(
        self, currency_id: int, value: Decimal
    ) -> AlternateCurrency | None:
        with self._session_factory() as session, session.begin():
            currency = session.get(AlternateCurrency, currency_id)
            if currency is None:
                raise ProductNotFoundError(f"No existe la moneda {currency_id}.")
            currency.value = value
            currency.source = "manual"
            currency.updated_at = datetime.utcnow()
            session.flush()
            session.refresh(currency)
            return currency

    def delete(self, currency_id: int) -> bool:
        with self._session_factory() as session, session.begin():
            currency = session.get(AlternateCurrency, currency_id)
            if currency is None:
                return False
            session.delete(currency)
            return True
