"""Servicio de monedas alternas del sistema."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from marcano.infrastructure.models import AlternateCurrency
from marcano.repositories.currency_base import CurrencyRateRepository
from marcano.services.rate_service import fetch_bcv_currency_rates


class CurrencyService:
    def __init__(
        self,
        repository: CurrencyRateRepository,
        fetcher=fetch_bcv_currency_rates,
    ) -> None:
        self._repository = repository
        self._fetcher = fetcher

    def bcv_rates(self) -> list[tuple[str, Decimal]]:
        return self._fetcher()

    def list_alternates(self) -> list[AlternateCurrency]:
        return self._repository.list_alternates()

    def replace_alternates(
        self, items: list[tuple[str, Decimal | None, str]]
    ) -> list[AlternateCurrency]:
        if not items:
            raise ValueError("Selecciona al menos una moneda.")
        names = [name for name, _value, _source in items]
        if any(not name.strip() for name in names):
            raise ValueError("El nombre de la moneda no puede estar vacio.")
        prepared: list[tuple[str, Decimal, str, datetime]] = []
        now = datetime.utcnow()
        for name, value, source in items:
            if value is None or value <= 0:
                raise ValueError(f"La tasa de '{name}' debe ser mayor que cero.")
            prepared.append((name.strip(), value, source, now))
        return self._repository.replace_alternates(prepared)

    def update_value(self, currency_id: int, value: Decimal) -> AlternateCurrency:
        return self._repository.update_value(currency_id, value)

    def delete(self, currency_id: int) -> bool:
        return self._repository.delete(currency_id)
