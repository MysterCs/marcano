"""Servicio de la tasa del dolar, con obtencion desde el BCV."""

from __future__ import annotations

import re
from datetime import datetime
from decimal import Decimal, InvalidOperation

import httpx

from marcano.domain.exceptions import RateUnavailableError
from marcano.infrastructure.models import DollarRate
from marcano.repositories.rate_base import RateRepository

BCV_URL = "https://www.bcv.org.ve/"
_USER_AGENT = "Mozilla/5.0 (compatible; MarcanoInventario/1.0)"


def fetch_bcv_dollar_rate(timeout: float = 15.0) -> Decimal:
    """Obtiene la tasa del dolar publicada en www.bcv.org.ve."""
    response = _request_bcv(timeout)
    html = response.text
    value = _parse_rate(html)
    if value is None:
        raise RateUnavailableError(
            "No se pudo leer la tasa del dolar desde el BCV. Configurala manual."
        )
    return value


BCV_CURRENCY_IDS: dict[str, str] = {
    "dolar": "Dolar",
    "euro": "Euro",
    "yuan": "Yuan",
    "rublo": "Rublo",
    "lira": "Lira",
    "peso.clp": "Peso chileno",
    "peso.cop": "Peso colombiano",
    "peso.pen": "Peso peruano",
}


def fetch_bcv_currency_rates(timeout: float = 15.0) -> list[tuple[str, Decimal]]:
    """Obtiene todas las divisas publicadas en www.bcv.org.ve."""
    response = _request_bcv(timeout)
    html = response.text
    rates: list[tuple[str, Decimal]] = []
    seen: set[str] = set()
    for identifier, pretty in BCV_CURRENCY_IDS.items():
        position = html.lower().find(f'id="{identifier}"')
        if position == -1:
            continue
        fragment = html[position : position + 3000]
        match = re.search(r"<strong[^>]*>\s*([\d.,]+)", fragment)
        if match is None:
            continue
        value = _normalize_rate(match.group(1))
        if value is None or identifier in seen:
            continue
        seen.add(identifier)
        rates.append((pretty, value))
    if not rates:
        raise RateUnavailableError(
            "No se pudo leer ninguna divisa desde el BCV. Configura las tasas manual."
        )
    return rates


def _normalize_rate(raw: str) -> Decimal | None:
    text = raw.strip()
    if "," in text:
        text = text.replace(".", "").replace(",", ".")
    try:
        value = Decimal(text)
    except InvalidOperation:
        return None
    return value if value > 0 else None


def _request_bcv(timeout: float) -> httpx.Response:
    headers = {"User-Agent": _USER_AGENT}
    try:
        response = httpx.get(BCV_URL, headers=headers, timeout=timeout, follow_redirects=True)
        response.raise_for_status()
        return response
    except httpx.HTTPError:
        # El certificado del BCV suele presentar problemas: reintenta sin validarlo.
        response = httpx.get(
            BCV_URL,
            headers=headers,
            timeout=timeout,
            follow_redirects=True,
            verify=False,
        )
        response.raise_for_status()
        return response


def _parse_rate(html: str) -> Decimal | None:
    match = re.search(
        r'id="dolar".{0,4000}?<strong[^>]*>\s*([\d.,]+)',
        html,
        flags=re.DOTALL | re.IGNORECASE,
    )
    if match is None:
        match = re.search(
            r"[Dd][oó]lar.{0,4000}?<strong[^>]*>\s*([\d.,]+)",
            html,
            flags=re.DOTALL,
        )
    if match is None:
        return None
    return _normalize_rate(match.group(1))


class RateService:
    def __init__(self, repository: RateRepository, fetcher=fetch_bcv_dollar_rate) -> None:
        self._repository = repository
        self._fetcher = fetcher

    def current(self) -> tuple[Decimal | None, str | None, datetime | None]:
        rate = self._repository.get_current()
        if rate is None:
            return None, None, None
        return rate.value, rate.source, rate.updated_at

    def refresh_from_bcv(self) -> DollarRate:
        value = self._fetcher()
        return self._repository.save(value, "BCV", datetime.utcnow())

    def set_manual(self, value: Decimal) -> DollarRate:
        return self._repository.save(value, "manual", datetime.utcnow())
