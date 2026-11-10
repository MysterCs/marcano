from marcano.domain.categories import infer_category


def test_infer_category_from_name() -> None:
    assert infer_category("PATCH CORD F.O SC/APC-SC/APC 3M") == "Patch Cords y Pig Tails"
    assert infer_category("BANDEJA DISTRIBUCION F.O 24 PUERTOS") == "Racks, Bandejas y Gabinetes"
    assert infer_category("SWITCH 24 PUERTOS GIGABIT") == "Equipos Activos y Red"
    assert infer_category("SPLITTER PLC 1X8 SC/APC") == "Fibra Óptica y Empalmes"
    assert infer_category("CONECTOR RJ-45 CAT6") == "Cableado y Conectividad"
    assert infer_category("CANALETA RANURADA 40X40") == "Canalización y Herrajes"
    assert infer_category("BATERIA 12V 9AMP KIJO") == "Energía y Respaldo"
    assert infer_category("ETIQUETA NYLON 9 MM") == "Herramientas y Consumibles"
    assert infer_category("PRODUCTO GENERICO SIN REGLA") == "Otros / General"


def test_descriptive_statistics_and_export_endpoints(client) -> None:
    create_resp = client.post(
        "/api/products",
        json={
            "sku": "PATCH-001",
            "name": "PATCH CORD F.O LC/UPC 2M",
            "initial_stock": 20,
            "min_stock": 5,
            "unit_cost": "4.50",
            "sale_price": "8.00",
        },
    )
    assert create_resp.status_code == 201
    product = create_resp.json()
    assert product["category"] == "Patch Cords y Pig Tails"

    categories_resp = client.get("/api/categories")
    assert categories_resp.status_code == 200
    assert "Patch Cords y Pig Tails" in categories_resp.json()

    stats_resp = client.get("/api/statistics/descriptive")
    assert stats_resp.status_code == 200
    stats = stats_resp.json()
    assert stats["total_products"] >= 1
    assert stats["stock_distribution"]["mean"] > 0
    assert any(c["category"] == "Patch Cords y Pig Tails" for c in stats["categories"])

    csv_resp = client.get("/api/statistics/export?format=csv")
    assert csv_resp.status_code == 200
    assert "text/csv" in csv_resp.headers["content-type"]
    assert "PATCH-001" in csv_resp.text

    xlsx_resp = client.get("/api/statistics/export?format=xlsx")
    assert xlsx_resp.status_code == 200
    assert (
        xlsx_resp.headers["content-type"]
        == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    assert len(xlsx_resp.content) > 100
