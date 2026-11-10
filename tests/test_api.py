def test_health(client):
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_product_sale_purchase_and_projection_endpoints(client):
    created = client.post(
        "/api/products",
        json={
            "sku": "API-001",
            "name": "Producto API",
            "initial_stock": 20,
            "min_stock": 3,
            "unit_cost": 8.5,
            "sale_price": 12,
        },
    )
    assert created.status_code == 201
    product_id = created.json()["id"]

    sale = client.post(f"/api/products/{product_id}/sales", json={"quantity": 4})
    assert sale.status_code == 200
    assert sale.json()["stock"] == 16

    purchase = client.post(
        f"/api/products/{product_id}/purchases",
        json={"quantity": 2, "unit_cost": 9},
    )
    assert purchase.status_code == 200
    assert purchase.json()["stock"] == 18

    summary = client.get("/api/inventory/summary")
    assert summary.status_code == 200
    assert summary.json()["units"] == 18

    projection = client.get(
        f"/api/projections/{product_id}",
        params={"movement": "sale", "periods": 3, "strategy": "moving_average"},
    )
    assert projection.status_code == 200
    assert len(projection.json()) == 3
    assert projection.json()[0]["quantity"] == 4.0


def test_api_returns_domain_errors(client):
    missing = client.post("/api/products/999/sales", json={"quantity": 1})
    assert missing.status_code == 404

    product = {
        "sku": "API-002",
        "name": "Producto API",
        "initial_stock": 1,
    }
    assert client.post("/api/products", json=product).status_code == 201
    assert client.post("/api/products", json=product).status_code == 409

    insufficient = client.post("/api/products/1/sales", json={"quantity": 2})
    assert insufficient.status_code == 422
