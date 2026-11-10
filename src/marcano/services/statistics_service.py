from __future__ import annotations

import csv
import io
from dataclasses import dataclass

import numpy as np
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill

from marcano.domain.categories import infer_category
from marcano.infrastructure.models import Product
from marcano.repositories.base import InventoryRepository


@dataclass(frozen=True, slots=True)
class MetricDistribution:
    mean: float
    median: float
    mode: float
    std_dev: float
    variance: float
    minimum: float
    maximum: float
    p25: float
    p75: float
    p90: float
    iqr: float
    cv: float


@dataclass(frozen=True, slots=True)
class StockHealthSummary:
    optimal_count: int
    low_stock_count: int
    out_of_stock_count: int
    inactive_count: int


@dataclass(frozen=True, slots=True)
class CategoryStat:
    category: str
    product_count: int
    total_units: int
    total_value: float
    share_percentage: float
    low_stock_count: int
    avg_stock: float
    avg_unit_cost: float


@dataclass(frozen=True, slots=True)
class TopProductStat:
    id: int
    sku: str
    name: str
    category: str
    stock: int
    unit_cost: float
    total_value: float


@dataclass(frozen=True, slots=True)
class MonthlyRotationPoint:
    period: str
    entries: float
    exits: float


@dataclass(frozen=True, slots=True)
class DescriptiveStatisticsReport:
    total_products: int
    total_units: int
    total_inventory_value: float
    active_categories: int
    stock_distribution: MetricDistribution
    cost_distribution: MetricDistribution
    value_distribution: MetricDistribution
    stock_health: StockHealthSummary
    categories: list[CategoryStat]
    top_by_value: list[TopProductStat]
    top_by_stock: list[TopProductStat]
    monthly_rotation: list[MonthlyRotationPoint]


class StatisticsService:
    def __init__(self, repository: InventoryRepository) -> None:
        self._repository = repository

    def descriptive_report(self, category: str | None = None) -> DescriptiveStatisticsReport:
        all_products = self._repository.list_products()
        products = self._filter_products(all_products, category)

        stocks = [float(p.stock) for p in products]
        costs = [float(p.unit_cost) for p in products]
        values = [float(p.stock) * float(p.unit_cost) for p in products]

        stock_dist = self._compute_distribution(stocks)
        cost_dist = self._compute_distribution(costs)
        value_dist = self._compute_distribution(values)

        optimal = sum(1 for p in products if p.is_active and p.stock > p.min_stock)
        low_stock = sum(1 for p in products if p.is_active and 0 < p.stock <= p.min_stock)
        out_of_stock = sum(1 for p in products if p.is_active and p.stock == 0)
        inactive = sum(1 for p in products if not p.is_active)

        categories = self._compute_category_stats(all_products)
        top_value = sorted(
            products,
            key=lambda p: (float(p.stock) * float(p.unit_cost), p.stock),
            reverse=True,
        )[:10]
        top_stock = sorted(
            products,
            key=lambda p: (p.stock, float(p.unit_cost)),
            reverse=True,
        )[:10]

        rotation = [
            MonthlyRotationPoint(period=period, entries=entries, exits=exits)
            for period, entries, exits in self._repository.monthly_rotation_summary()
        ]

        return DescriptiveStatisticsReport(
            total_products=len(products),
            total_units=sum(p.stock for p in products),
            total_inventory_value=round(sum(values), 2),
            active_categories=len(categories),
            stock_distribution=stock_dist,
            cost_distribution=cost_dist,
            value_distribution=value_dist,
            stock_health=StockHealthSummary(
                optimal_count=optimal,
                low_stock_count=low_stock,
                out_of_stock_count=out_of_stock,
                inactive_count=inactive,
            ),
            categories=categories,
            top_by_value=[self._to_top_stat(p) for p in top_value],
            top_by_stock=[self._to_top_stat(p) for p in top_stock],
            monthly_rotation=rotation,
        )

    def export_csv(self, category: str | None = None) -> bytes:
        report = self.descriptive_report(category)
        products = self._filter_products(self._repository.list_products(), category)

        buffer = io.StringIO()
        writer = csv.writer(buffer)

        writer.writerow(["REPORTE DE ESTADISTICAS DESCRIPTIVAS - MARCANO INVENTARIO"])
        writer.writerow(["Categoria filtrada", category or "Todas"])
        writer.writerow(["Total productos", report.total_products])
        writer.writerow(["Total unidades", report.total_units])
        writer.writerow(["Valor total inventario (USD)", f"{report.total_inventory_value:.2f}"])
        writer.writerow([])

        writer.writerow(
            [
                "MEDIDAS DESCRIPTIVAS",
                "EXISTENCIAS",
                "COSTO UNITARIO (USD)",
                "VALOR TOTAL (USD)",
            ]
        )
        metrics = [
            ("Media", "mean"),
            ("Mediana (P50)", "median"),
            ("Moda", "mode"),
            ("Desviacion Estandar", "std_dev"),
            ("Varianza", "variance"),
            ("Minimo", "minimum"),
            ("Maximo", "maximum"),
            ("Percentil 25 (Q1)", "p25"),
            ("Percentil 75 (Q3)", "p75"),
            ("Percentil 90 (P90)", "p90"),
            ("Rango Intercuartilico (IQR)", "iqr"),
            ("Coeficiente de Variacion (%)", "cv"),
        ]
        for label, attr in metrics:
            writer.writerow(
                [
                    label,
                    getattr(report.stock_distribution, attr),
                    getattr(report.cost_distribution, attr),
                    getattr(report.value_distribution, attr),
                ]
            )
        writer.writerow([])

        writer.writerow(
            [
                "CATEGORIA",
                "PRODUCTOS",
                "UNIDADES",
                "VALOR TOTAL (USD)",
                "PARTICIPACION (%)",
                "STOCK BAJO",
                "STOCK PROMEDIO",
                "COSTO PROMEDIO (USD)",
            ]
        )
        for cat in report.categories:
            writer.writerow(
                [
                    cat.category,
                    cat.product_count,
                    cat.total_units,
                    f"{cat.total_value:.2f}",
                    f"{cat.share_percentage:.2f}",
                    cat.low_stock_count,
                    f"{cat.avg_stock:.2f}",
                    f"{cat.avg_unit_cost:.2f}",
                ]
            )
        writer.writerow([])

        writer.writerow(
            [
                "SKU",
                "NOMBRE",
                "CATEGORIA",
                "MODELO",
                "EXISTENCIAS",
                "STOCK MINIMO",
                "UNIDAD",
                "COSTO UNITARIO (USD)",
                "PRECIO VENTA (USD)",
                "VALOR TOTAL (USD)",
                "ESTADO",
            ]
        )
        for p in products:
            cat_name = getattr(p, "category", None) or infer_category(p.name)
            total_val = float(p.stock) * float(p.unit_cost)
            if not p.is_active:
                status_label = "Inactivo"
            elif p.stock == 0:
                status_label = "Agotado"
            elif p.stock <= p.min_stock:
                status_label = "Bajo stock"
            else:
                status_label = "Optimo"
            writer.writerow(
                [
                    p.sku,
                    p.name,
                    cat_name,
                    p.model or "",
                    p.stock,
                    p.min_stock,
                    p.unit,
                    f"{float(p.unit_cost):.2f}",
                    f"{float(p.sale_price):.2f}",
                    f"{total_val:.2f}",
                    status_label,
                ]
            )

        return ("\ufeff" + buffer.getvalue()).encode("utf-8")

    def export_excel(self, category: str | None = None) -> bytes:
        report = self.descriptive_report(category)
        products = self._filter_products(self._repository.list_products(), category)

        wb = Workbook()
        header_fill = PatternFill(start_color="E11D48", end_color="E11D48", fill_type="solid")
        header_font = Font(color="FFFFFF", bold=True)
        center = Alignment(horizontal="center")

        # Hoja 1: Resumen Estadístico
        ws_summary = wb.active
        assert ws_summary is not None
        ws_summary.title = "Resumen Estadistico"
        ws_summary.append(["Indicador", "Existencias", "Costo Unitario (USD)", "Valor Total (USD)"])
        for cell in ws_summary[1]:
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = center

        rows = [
            ("Media", "mean"),
            ("Mediana (P50)", "median"),
            ("Moda", "mode"),
            ("Desviacion Estandar", "std_dev"),
            ("Varianza", "variance"),
            ("Minimo", "minimum"),
            ("Maximo", "maximum"),
            ("Percentil 25 (Q1)", "p25"),
            ("Percentil 75 (Q3)", "p75"),
            ("Percentil 90 (P90)", "p90"),
            ("Rango Intercuartilico (IQR)", "iqr"),
            ("Coeficiente de Variacion (%)", "cv"),
        ]
        for label, attr in rows:
            ws_summary.append(
                [
                    label,
                    getattr(report.stock_distribution, attr),
                    getattr(report.cost_distribution, attr),
                    getattr(report.value_distribution, attr),
                ]
            )

        ws_summary.append([])
        ws_summary.append(["Salud del Inventario", "Cantidad de Productos"])
        ws_summary.append(["Stock Optimo", report.stock_health.optimal_count])
        ws_summary.append(["Bajo Stock", report.stock_health.low_stock_count])
        ws_summary.append(["Agotados (Stock 0)", report.stock_health.out_of_stock_count])
        ws_summary.append(["Inactivos", report.stock_health.inactive_count])

        # Hoja 2: Estadísticas por Categoría
        ws_cat = wb.create_sheet(title="Por Categoria")
        ws_cat.append(
            [
                "Categoria",
                "Productos",
                "Unidades Totales",
                "Valor Total (USD)",
                "Participacion (%)",
                "Bajo Stock",
                "Stock Promedio",
                "Costo Promedio (USD)",
            ]
        )
        for cell in ws_cat[1]:
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = center

        for cat in report.categories:
            ws_cat.append(
                [
                    cat.category,
                    cat.product_count,
                    cat.total_units,
                    cat.total_value,
                    cat.share_percentage,
                    cat.low_stock_count,
                    cat.avg_stock,
                    cat.avg_unit_cost,
                ]
            )

        # Hoja 3: Top Productos
        ws_top = wb.create_sheet(title="Top Productos")
        ws_top.append(
            [
                "Ranking",
                "SKU",
                "Nombre",
                "Categoria",
                "Existencias",
                "Costo Unitario (USD)",
                "Valor Total (USD)",
            ]
        )
        for cell in ws_top[1]:
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = center

        for idx, item in enumerate(report.top_by_value, start=1):
            ws_top.append(
                [
                    idx,
                    item.sku,
                    item.name,
                    item.category,
                    item.stock,
                    item.unit_cost,
                    item.total_value,
                ]
            )

        # Hoja 4: Inventario Clasificado
        ws_inv = wb.create_sheet(title="Inventario Clasificado")
        ws_inv.append(
            [
                "SKU",
                "Nombre",
                "Categoria",
                "Modelo",
                "Existencias",
                "Stock Minimo",
                "Unidad",
                "Costo Unitario (USD)",
                "Precio Venta (USD)",
                "Valor Total (USD)",
            ]
        )
        for cell in ws_inv[1]:
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = center

        for p in products:
            cat_name = getattr(p, "category", None) or infer_category(p.name)
            ws_inv.append(
                [
                    p.sku,
                    p.name,
                    cat_name,
                    p.model or "",
                    p.stock,
                    p.min_stock,
                    p.unit,
                    float(p.unit_cost),
                    float(p.sale_price),
                    round(float(p.stock) * float(p.unit_cost), 2),
                ]
            )

        output = io.BytesIO()
        wb.save(output)
        return output.getvalue()

    @staticmethod
    def _filter_products(products: list[Product], category: str | None) -> list[Product]:
        if not category or not category.strip() or category.strip().lower() == "todas":
            return products
        target = category.strip().lower()
        return [
            p
            for p in products
            if ((getattr(p, "category", None) or infer_category(p.name)).lower() == target)
        ]

    @staticmethod
    def _compute_distribution(values: list[float]) -> MetricDistribution:
        if not values:
            return MetricDistribution(
                mean=0.0,
                median=0.0,
                mode=0.0,
                std_dev=0.0,
                variance=0.0,
                minimum=0.0,
                maximum=0.0,
                p25=0.0,
                p75=0.0,
                p90=0.0,
                iqr=0.0,
                cv=0.0,
            )

        arr = np.asarray(values, dtype=float)
        mean = float(np.mean(arr))
        median = float(np.median(arr))
        std_dev = float(np.std(arr))
        variance = float(np.var(arr))
        minimum = float(np.min(arr))
        maximum = float(np.max(arr))
        p25, p75, p90 = (float(x) for x in np.percentile(arr, [25, 75, 90]))
        iqr = p75 - p25
        cv = (std_dev / mean * 100.0) if mean > 0 else 0.0

        unique_vals, counts = np.unique(np.round(arr, 2), return_counts=True)
        mode = float(unique_vals[int(np.argmax(counts))]) if len(unique_vals) > 0 else 0.0

        return MetricDistribution(
            mean=round(mean, 2),
            median=round(median, 2),
            mode=round(mode, 2),
            std_dev=round(std_dev, 2),
            variance=round(variance, 2),
            minimum=round(minimum, 2),
            maximum=round(maximum, 2),
            p25=round(p25, 2),
            p75=round(p75, 2),
            p90=round(p90, 2),
            iqr=round(iqr, 2),
            cv=round(cv, 2),
        )

    @staticmethod
    def _compute_category_stats(products: list[Product]) -> list[CategoryStat]:
        buckets: dict[str, list[Product]] = {}
        total_value_all = sum(float(p.stock) * float(p.unit_cost) for p in products)
        total_products_all = len(products)

        for p in products:
            cat_name = getattr(p, "category", None) or infer_category(p.name)
            buckets.setdefault(cat_name, []).append(p)

        stats: list[CategoryStat] = []
        for cat_name, items in buckets.items():
            count = len(items)
            units = sum(p.stock for p in items)
            val = sum(float(p.stock) * float(p.unit_cost) for p in items)
            low_stock = sum(1 for p in items if p.stock <= p.min_stock)
            avg_stock = units / count if count > 0 else 0.0
            avg_cost = sum(float(p.unit_cost) for p in items) / count if count > 0 else 0.0
            share = (
                (val / total_value_all * 100.0)
                if total_value_all > 0
                else (count / total_products_all * 100.0 if total_products_all > 0 else 0.0)
            )
            stats.append(
                CategoryStat(
                    category=cat_name,
                    product_count=count,
                    total_units=units,
                    total_value=round(val, 2),
                    share_percentage=round(share, 2),
                    low_stock_count=low_stock,
                    avg_stock=round(avg_stock, 2),
                    avg_unit_cost=round(avg_cost, 2),
                )
            )

        return sorted(stats, key=lambda s: (s.total_value, s.product_count), reverse=True)

    @staticmethod
    def _to_top_stat(product: Product) -> TopProductStat:
        cat_name = getattr(product, "category", None) or infer_category(product.name)
        unit_cost = float(product.unit_cost)
        return TopProductStat(
            id=product.id,
            sku=product.sku,
            name=product.name,
            category=cat_name,
            stock=product.stock,
            unit_cost=round(unit_cost, 2),
            total_value=round(product.stock * unit_cost, 2),
        )
