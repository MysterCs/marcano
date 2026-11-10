from decimal import Decimal


def test_bcv_currencies_requires_auth(anonymous_client):
    assert anonymous_client.get("/api/rate/bcv").status_code == 401


def test_alternates_empty(client):
    response = client.get("/api/rate/alternates")
    assert response.status_code == 200
    assert response.json() == []


def test_set_alternates_with_two_currencies(client):
    response = client.put(
        "/api/rate/alternates",
        json=[
            {"name": "Euro", "value": 1001.19, "source": "bcv"},
            {"name": "Yuan", "value": 134.45, "source": "bcv"},
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert [item["name"] for item in body] == ["Euro", "Yuan"]
    assert all(item["source"] == "bcv" for item in body)
    assert all(item["updated_at"] for item in body)


def test_set_alternates_replaces_previous(client):
    first = client.put(
        "/api/rate/alternates",
        json=[{"name": "Euro", "value": 1001.19}],
    )
    assert first.status_code == 200
    second = client.put(
        "/api/rate/alternates",
        json=[{"name": "Rublo", "value": 10.95, "source": "bcv"}],
    )
    assert second.status_code == 200
    names = [item["name"] for item in second.json()]
    assert "Euro" not in names
    assert "Rublo" in names


def test_set_alternates_validates(client):
    empty = client.put("/api/rate/alternates", json=[])
    assert empty.status_code == 422
    invalid = client.put(
        "/api/rate/alternates", json=[{"name": "Euro", "value": -5}]
    )
    assert invalid.status_code == 422


def test_update_alternate_value_marks_manual(client):
    created = client.put(
        "/api/rate/alternates",
        json=[{"name": "Euro", "value": 1001.19, "source": "bcv"}],
    ).json()[0]

    response = client.patch(
        f"/api/rate/alternates/{created['id']}", json={"value": 1050.0}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["value"] == 1050.0
    assert body["source"] == "manual"


def test_delete_alternate(client):
    created = client.put(
        "/api/rate/alternates",
        json=[{"name": "Lira", "value": 17.89, "source": "bcv"}],
    ).json()[0]

    response = client.delete(f"/api/rate/alternates/{created['id']}")
    assert response.status_code == 204
    assert client.get("/api/rate/alternates").json() == []


def test_currency_service_with_stub_repository():
    from datetime import datetime

    from marcano.infrastructure.models import AlternateCurrency
    from marcano.services.currency_service import CurrencyService

    class StubRepository:
        def __init__(self):
            self.items: list[AlternateCurrency] = []

        def list_alternates(self):
            return self.items

        def replace_alternates(self, prepared):
            self.items = [
                AlternateCurrency(name=n, value=v, source=s, updated_at=u)
                for n, v, s, u in prepared
            ]
            return self.items

        def update_value(self, currency_id, value):
            return None

        def delete(self, currency_id):
            return False

    service = CurrencyService(StubRepository(), fetcher=lambda: [("Euro", Decimal("1"))])
    result = service.replace_alternates([("Euro", Decimal("1001.19"), "bcv")])
    assert result[0].value == Decimal("1001.19")
    assert result[0].updated_at is not None
    assert isinstance(result[0].updated_at, datetime)
