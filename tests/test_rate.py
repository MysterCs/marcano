from decimal import Decimal

from marcano.services.rate_service import RateService


def test_current_rate_without_setup(client):
    response = client.get("/api/rate/current")
    assert response.status_code == 200
    assert response.json()["value"] is None


def test_set_manual_rate(client):
    response = client.put("/api/rate", json={"value": 42.5})
    assert response.status_code == 200
    body = response.json()
    assert body["value"] == 42.5
    assert body["source"] == "manual"
    assert body["updated_at"] is not None

    current = client.get("/api/rate/current").json()
    assert current["value"] == 42.5


def test_refresh_rate_from_bcv(client, monkeypatch):
    monkeypatch.setattr(
        "marcano.services.rate_service.fetch_bcv_dollar_rate",
        lambda: Decimal("265.72"),
    )
    response = client.post("/api/rate/refresh")
    assert response.status_code == 200
    body = response.json()
    assert body["value"] == 265.72
    assert body["source"] == "BCV"


def test_rate_requires_authentication(anonymous_client):
    assert anonymous_client.get("/api/rate/current").status_code == 401
    assert anonymous_client.put("/api/rate", json={"value": 1}).status_code == 401


def test_rate_service_saves_with_stub_repository():
    from decimal import Decimal

    from marcano.infrastructure.models import DollarRate

    class StubRepository:
        def __init__(self):
            self.saved = None

        def get_current(self):
            return self.saved

        def save(self, value, source, updated_at):
            self.saved = DollarRate(value=value, source=source, updated_at=updated_at)
            return self.saved

    service = RateService(StubRepository(), fetcher=lambda: Decimal("99.99"))
    rate = service.refresh_from_bcv()
    assert rate.value == Decimal("99.99")
    assert rate.source == "BCV"
