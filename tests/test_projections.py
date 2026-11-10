import pandas as pd
import pytest

from marcano.domain.entities import MovementType
from marcano.factories.projection_factory import ProjectionFactory
from marcano.services.inventory_service import InventoryService
from marcano.services.projection_service import ProjectionService
from marcano.services.projection_strategies import LinearTrendProjection, MovingAverageProjection


def test_projection_factory_resolves_strategies():
    assert isinstance(ProjectionFactory.create("moving_average"), MovingAverageProjection)
    assert isinstance(ProjectionFactory.create("linear_trend"), LinearTrendProjection)
    with pytest.raises(ValueError, match="Estrategia desconocida"):
        ProjectionFactory.create("unknown")


def test_linear_trend_projects_non_negative_values():
    history = pd.Series([10.0, 20.0, 30.0])
    assert LinearTrendProjection().forecast(history, 2) == pytest.approx([40.0, 50.0])

    decreasing = pd.Series([10.0, 0.0])
    assert LinearTrendProjection().forecast(decreasing, 2) == [0.0, 0.0]


def test_sales_projection_uses_monthly_history(repository):
    inventory = InventoryService(repository)
    product = inventory.create_product(sku="P-001", name="Producto", initial_stock=30)
    inventory.register_sale(product.id, 12)

    points = ProjectionService(repository).project(
        product.id,
        movement=MovementType.SALE,
        periods=6,
        strategy="moving_average",
    )

    assert len(points) == 6
    assert all(point.quantity == 12.0 for point in points)
    assert all(point.movement == MovementType.SALE for point in points)
    assert points[0].period < points[-1].period
