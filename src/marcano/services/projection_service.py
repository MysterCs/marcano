import pandas as pd

from marcano.domain.entities import MovementRecord, MovementType, ProjectionPoint
from marcano.factories.projection_factory import ProjectionFactory
from marcano.repositories.base import InventoryRepository


class ProjectionService:
    def __init__(self, repository: InventoryRepository) -> None:
        self._repository = repository

    def project(
        self,
        product_id: int,
        movement: MovementType = MovementType.SALE,
        periods: int = 6,
        strategy: str = "moving_average",
    ) -> list[ProjectionPoint]:
        if not 1 <= periods <= 36:
            raise ValueError("El horizonte debe estar entre 1 y 36 meses.")

        self._repository.get_product(product_id)
        history = self._history(product_id, movement)
        monthly_history = self._monthly_series(history)
        forecaster = ProjectionFactory.create(strategy)
        values = forecaster.forecast(monthly_history, periods)

        if monthly_history.empty:
            first_period = pd.Timestamp.now().normalize().replace(day=1) + pd.offsets.MonthBegin()
        else:
            first_period = monthly_history.index[-1] + pd.offsets.MonthBegin()
        future_periods = pd.date_range(first_period, periods=periods, freq="MS")

        return [
            ProjectionPoint(
                period=period.date(),
                quantity=round(float(value), 2),
                movement=movement,
            )
            for period, value in zip(future_periods, values, strict=True)
        ]

    def _history(self, product_id: int, movement: MovementType) -> list[MovementRecord]:
        if movement == MovementType.SALE:
            return self._repository.sales_history(product_id)
        return self._repository.purchases_history(product_id)

    @staticmethod
    def _monthly_series(history: list[MovementRecord]) -> pd.Series:
        if not history:
            return pd.Series(dtype=float)

        frame = pd.DataFrame(
            {
                "occurred_at": pd.to_datetime([item.occurred_at for item in history]),
                "quantity": [item.quantity for item in history],
            }
        )
        series = frame.set_index("occurred_at")["quantity"].resample("MS").sum()
        complete_index = pd.date_range(series.index.min(), series.index.max(), freq="MS")
        return series.reindex(complete_index, fill_value=0.0).astype(float)
