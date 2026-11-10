from collections.abc import Callable

from marcano.services.projection_strategies import (
    LinearTrendProjection,
    MovingAverageProjection,
    ProjectionStrategy,
)


class ProjectionFactory:
    """Resuelve algoritmos de proyeccion por nombre."""

    _strategies: dict[str, Callable[[], ProjectionStrategy]] = {
        "moving_average": MovingAverageProjection,
        "linear_trend": LinearTrendProjection,
    }

    @classmethod
    def create(cls, name: str) -> ProjectionStrategy:
        try:
            return cls._strategies[name.lower()]()
        except KeyError as exc:
            available = ", ".join(cls.available())
            raise ValueError(f"Estrategia desconocida '{name}'. Disponibles: {available}.") from exc

    @classmethod
    def available(cls) -> tuple[str, ...]:
        return tuple(cls._strategies)
