from abc import ABC, abstractmethod

import numpy as np
import pandas as pd


class ProjectionStrategy(ABC):
    @abstractmethod
    def forecast(self, history: pd.Series, periods: int) -> list[float]:
        raise NotImplementedError


class MovingAverageProjection(ProjectionStrategy):
    def __init__(self, window: int = 3) -> None:
        self.window = window

    def forecast(self, history: pd.Series, periods: int) -> list[float]:
        if history.empty:
            return [0.0] * periods
        value = float(history.tail(self.window).mean())
        return [max(0.0, value)] * periods


class LinearTrendProjection(ProjectionStrategy):
    def forecast(self, history: pd.Series, periods: int) -> list[float]:
        if history.empty:
            return [0.0] * periods
        if len(history) == 1:
            return [max(0.0, float(history.iloc[0]))] * periods

        x = np.arange(len(history), dtype=float)
        slope, intercept = np.polyfit(x, history.to_numpy(dtype=float), 1)
        future_x = np.arange(len(history), len(history) + periods, dtype=float)
        return [max(0.0, float(value)) for value in slope * future_x + intercept]
