from datetime import datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from marcano.infrastructure.models import DollarRate
from marcano.repositories.rate_base import RateRepository


class SQLAlchemyRateRepository(RateRepository):
    def __init__(self, session_factory: sessionmaker[Session]) -> None:
        self._session_factory = session_factory

    def get_current(self) -> DollarRate | None:
        with self._session_factory() as session:
            rate = session.scalars(
                select(DollarRate).order_by(DollarRate.id).limit(1)
            ).first()
            if rate is None:
                return None
            session.refresh(rate)
            return rate

    def save(self, value: Decimal, source: str, updated_at: datetime) -> DollarRate:
        with self._session_factory() as session, session.begin():
            rate = session.scalars(
                select(DollarRate).order_by(DollarRate.id).limit(1)
            ).first()
            if rate is None:
                rate = DollarRate(value=value, source=source, updated_at=updated_at)
                session.add(rate)
            else:
                rate.value = value
                rate.source = source
                rate.updated_at = updated_at
            session.flush()
            session.refresh(rate)
            return rate
