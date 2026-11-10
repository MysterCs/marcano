from decimal import Decimal

import pytest

from marcano.domain.exceptions import DuplicateSKUError, InsufficientStockError
from marcano.services.inventory_service import InventoryService


def test_inventory_flow(repository):
    service = InventoryService(repository)
    product = service.create_product(
        sku="A-001",
        name="Articulo",
        initial_stock=20,
        min_stock=5,
        unit_cost=Decimal("10.00"),
        sale_price=Decimal("15.00"),
    )

    service.register_sale(product.id, 3)
    updated = service.register_purchase(product.id, 5, Decimal("12.00"))
    summary = service.summary()

    assert updated.stock == 22
    assert updated.unit_cost == Decimal("12.00")
    assert summary.products == 1
    assert summary.units == 22
    assert summary.low_stock == 0
    assert summary.inventory_value == Decimal("264.00")
    assert len(repository.sales_history(product.id)) == 1
    assert len(repository.purchases_history(product.id)) == 1


def test_sale_cannot_exceed_stock(repository):
    service = InventoryService(repository)
    product = service.create_product(sku="A-002", name="Articulo", initial_stock=2)

    with pytest.raises(InsufficientStockError):
        service.register_sale(product.id, 3)

    assert repository.get_product(product.id).stock == 2


def test_sku_must_be_unique(repository):
    service = InventoryService(repository)
    service.create_product(sku="A-003", name="Primero")

    with pytest.raises(DuplicateSKUError):
        service.create_product(sku="A-003", name="Segundo")


def test_update_product_records_user(client):
    created = client.post(
        "/api/products",
        json={"sku": "A-010", "name": "Original", "initial_stock": 10},
    )
    assert created.status_code == 201
    product_id = created.json()["id"]

    response = client.patch(
        f"/api/products/{product_id}",
        json={"name": "Editado", "stock": 25, "sale_price": 99.5},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Editado"
    assert body["stock"] == 25
    assert body["sale_price"] == 99.5
    assert body["updated_by_user_id"] is not None
    assert body["updated_by_user_name"] == "Usuario de Pruebas"
    assert body["updated_at"] is not None

    listing = client.get("/api/products").json()
    assert listing[0]["updated_by_user_name"] == "Usuario de Pruebas"


def test_update_product_partial_keeps_other_fields(client):
    product_id = client.post(
        "/api/products",
        json={"sku": "A-011", "name": "Original", "unit_cost": 5.0},
    ).json()["id"]

    response = client.patch(f"/api/products/{product_id}", json={"unit": "KG"})
    assert response.status_code == 200
    body = response.json()
    assert body["unit"] == "KG"
    assert body["name"] == "Original"
    assert body["unit_cost"] == 5.0


def test_update_product_rejects_negative_stock(client):
    product_id = client.post(
        "/api/products", json={"sku": "A-012", "name": "Original"}
    ).json()["id"]

    response = client.patch(f"/api/products/{product_id}", json={"stock": -3})
    assert response.status_code == 422


def test_update_unknown_product_returns_404(client):
    response = client.patch("/api/products/999", json={"name": "Nada"})
    assert response.status_code == 404


def test_update_requires_authentication(anonymous_client):
    response = anonymous_client.patch("/api/products/1", json={"name": "Nada"})
    assert response.status_code == 401
