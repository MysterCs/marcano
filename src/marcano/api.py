from functools import lru_cache
from typing import Annotated

import uvicorn
from fastapi import Depends, FastAPI, Query, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from marcano.config import get_settings
from marcano.domain.categories import ALL_CATEGORIES, infer_category
from marcano.domain.entities import MovementType, ProjectionPoint
from marcano.domain.exceptions import (
    AuthenticationError,
    DuplicateCedulaError,
    DuplicateSKUError,
    InsufficientStockError,
    InvalidSessionError,
    ProductNotFoundError,
    RateUnavailableError,
)
from marcano.factories.repository_factory import RepositoryFactory
from marcano.infrastructure.models import User
from marcano.repositories.auth_base import AuthRepository
from marcano.repositories.base import InventoryRepository
from marcano.repositories.currency_base import CurrencyRateRepository
from marcano.repositories.rate_base import RateRepository
from marcano.schemas import (
    AlternateCurrencyCreate,
    AlternateCurrencyRead,
    AlternateCurrencyValueUpdate,
    BcvCurrencyRead,
    DescriptiveStatisticsRead,
    DollarRateRead,
    HealthRead,
    InventorySummaryRead,
    LoginRequest,
    ManualRateCreate,
    ProductCreate,
    ProductRead,
    ProductUpdate,
    ProjectionPointRead,
    PurchaseCreate,
    ReclassifyResultRead,
    SaleCreate,
    TokenRead,
    UserCreate,
    UserRead,
)
from marcano.services import rate_service
from marcano.services.auth_service import AuthService
from marcano.services.currency_service import CurrencyService
from marcano.services.inventory_service import InventoryService
from marcano.services.projection_service import ProjectionService
from marcano.services.rate_service import RateService
from marcano.services.statistics_service import StatisticsService


@lru_cache
def get_repository() -> InventoryRepository:
    return RepositoryFactory.create()


@lru_cache
def get_auth_repository() -> AuthRepository:
    return RepositoryFactory.create_auth()


@lru_cache
def get_rate_repository() -> RateRepository:
    return RepositoryFactory.create_rate()


@lru_cache
def get_currency_repository() -> CurrencyRateRepository:
    return RepositoryFactory.create_currency()


def get_inventory_service(
    repository: Annotated[InventoryRepository, Depends(get_repository)],
) -> InventoryService:
    return InventoryService(repository)


def get_projection_service(
    repository: Annotated[InventoryRepository, Depends(get_repository)],
) -> ProjectionService:
    return ProjectionService(repository)


def get_statistics_service(
    repository: Annotated[InventoryRepository, Depends(get_repository)],
) -> StatisticsService:
    return StatisticsService(repository)


def get_auth_service(
    repository: Annotated[AuthRepository, Depends(get_auth_repository)],
) -> AuthService:
    return AuthService(repository, get_settings())


def get_rate_service(
    repository: Annotated[RateRepository, Depends(get_rate_repository)],
) -> RateService:
    return RateService(repository, rate_service.fetch_bcv_dollar_rate)


def get_currency_service(
    repository: Annotated[CurrencyRateRepository, Depends(get_currency_repository)],
) -> CurrencyService:
    return CurrencyService(repository, rate_service.fetch_bcv_currency_rates)


bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    service: Annotated[AuthService, Depends(get_auth_service)],
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise InvalidSessionError("Debes iniciar sesion para continuar.")
    return service.user_from_token(credentials.credentials)


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title=settings.app_name, version="0.1.0")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.exception_handler(RateUnavailableError)
    async def rate_unavailable_handler(
        _request: Request, exc: RateUnavailableError
    ) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_502_BAD_GATEWAY, content={"detail": str(exc)})

    @app.exception_handler(ProductNotFoundError)
    async def not_found_handler(_request: Request, exc: ProductNotFoundError) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_404_NOT_FOUND, content={"detail": str(exc)})

    @app.exception_handler(DuplicateSKUError)
    async def duplicate_handler(_request: Request, exc: DuplicateSKUError) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": str(exc)})

    @app.exception_handler(DuplicateCedulaError)
    async def duplicate_cedula_handler(
        _request: Request, exc: DuplicateCedulaError
    ) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": str(exc)})

    @app.exception_handler(AuthenticationError)
    async def authentication_handler(
        _request: Request, exc: AuthenticationError
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"detail": str(exc)},
            headers={"WWW-Authenticate": "Bearer"},
        )

    @app.exception_handler(InvalidSessionError)
    async def session_handler(_request: Request, exc: InvalidSessionError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"detail": str(exc)},
            headers={"WWW-Authenticate": "Bearer"},
        )

    @app.exception_handler(InsufficientStockError)
    async def stock_handler(_request: Request, exc: InsufficientStockError) -> JSONResponse:
        return JSONResponse(
            status_code=422,
            content={"detail": str(exc)},
        )

    @app.exception_handler(ValueError)
    async def value_error_handler(_request: Request, exc: ValueError) -> JSONResponse:
        return JSONResponse(
            status_code=422,
            content={"detail": str(exc)},
        )

    @app.post(
        "/api/auth/register",
        response_model=UserRead,
        status_code=status.HTTP_201_CREATED,
        tags=["autenticacion"],
    )
    def register(
        data: UserCreate,
        service: Annotated[AuthService, Depends(get_auth_service)],
    ) -> UserRead:
        user = service.register(data.full_name, data.cedula, data.password)
        return UserRead.model_validate(user)

    @app.post("/api/auth/login", response_model=TokenRead, tags=["autenticacion"])
    def login(
        data: LoginRequest,
        service: Annotated[AuthService, Depends(get_auth_service)],
    ) -> TokenRead:
        user = service.authenticate(data.cedula, data.password)
        return TokenRead(
            access_token=service.create_access_token(user),
            user=UserRead.model_validate(user),
        )

    @app.get("/api/auth/me", response_model=UserRead, tags=["autenticacion"])
    def me(current_user: Annotated[User, Depends(get_current_user)]) -> UserRead:
        return UserRead.model_validate(current_user)

    @app.get("/api/health", response_model=HealthRead, tags=["sistema"])
    def health() -> HealthRead:
        return HealthRead(status="ok", service=settings.app_name)

    @app.get("/api/products", response_model=list[ProductRead], tags=["inventario"])
    def list_products(
        service: Annotated[InventoryService, Depends(get_inventory_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
        category: str | None = None,
        search: str | None = None,
    ) -> list[ProductRead]:
        products = service.list_products()
        result: list[ProductRead] = []
        target_cat = category.strip().lower() if category and category.strip() else None
        target_search = search.strip().lower() if search and search.strip() else None

        for product in products:
            dto = ProductRead.model_validate(product)
            if not dto.category or dto.category == "Otros / General":
                dto.category = getattr(product, "category", None) or infer_category(product.name)
            if target_cat and target_cat != "todas" and dto.category.lower() != target_cat:
                continue
            if target_search and (
                target_search not in dto.name.lower()
                and target_search not in dto.sku.lower()
                and target_search not in (dto.model or "").lower()
            ):
                continue
            result.append(dto)
        return result

    @app.get("/api/categories", response_model=list[str], tags=["inventario"])
    def list_categories(
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> list[str]:
        return list(ALL_CATEGORIES)

    @app.post(
        "/api/categories/reclassify",
        response_model=ReclassifyResultRead,
        tags=["inventario"],
    )
    def reclassify_categories(
        service: Annotated[InventoryService, Depends(get_inventory_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> ReclassifyResultRead:
        return ReclassifyResultRead(updated=service.reclassify_categories())

    @app.post(
        "/api/products",
        response_model=ProductRead,
        status_code=status.HTTP_201_CREATED,
        tags=["inventario"],
    )
    def create_product(
        data: ProductCreate,
        service: Annotated[InventoryService, Depends(get_inventory_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> ProductRead:
        product = service.create_product(**data.model_dump())
        return ProductRead.model_validate(product)

    @app.patch(
        "/api/products/{product_id}",
        response_model=ProductRead,
        tags=["inventario"],
    )
    def update_product(
        product_id: int,
        data: ProductUpdate,
        service: Annotated[InventoryService, Depends(get_inventory_service)],
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> ProductRead:
        changes = data.to_changes()
        product = service.update_product(
            product_id,
            changes,
            updated_by_user_id=current_user.id,
            updated_by_user_name=current_user.full_name,
        )
        return ProductRead.model_validate(product)

    @app.post(
        "/api/products/{product_id}/sales",
        response_model=ProductRead,
        tags=["ventas"],
    )
    def register_sale(
        product_id: int,
        data: SaleCreate,
        service: Annotated[InventoryService, Depends(get_inventory_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> ProductRead:
        product = service.register_sale(product_id, data.quantity, data.unit_price)
        return ProductRead.model_validate(product)

    @app.post(
        "/api/products/{product_id}/purchases",
        response_model=ProductRead,
        tags=["compras"],
    )
    def register_purchase(
        product_id: int,
        data: PurchaseCreate,
        service: Annotated[InventoryService, Depends(get_inventory_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> ProductRead:
        product = service.register_purchase(product_id, data.quantity, data.unit_cost)
        return ProductRead.model_validate(product)

    @app.get(
        "/api/inventory/summary",
        response_model=InventorySummaryRead,
        tags=["inventario"],
    )
    def inventory_summary(
        service: Annotated[InventoryService, Depends(get_inventory_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> InventorySummaryRead:
        summary = service.summary()
        return InventorySummaryRead(
            products=summary.products,
            units=summary.units,
            low_stock=summary.low_stock,
            inventory_value=float(summary.inventory_value),
        )

    @app.get("/api/rate/current", response_model=DollarRateRead, tags=["tasa"])
    def current_rate(
        service: Annotated[RateService, Depends(get_rate_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> DollarRateRead:
        value, source, updated_at = service.current()
        return DollarRateRead(value=value, source=source, updated_at=updated_at)

    @app.post("/api/rate/refresh", response_model=DollarRateRead, tags=["tasa"])
    def refresh_rate(
        service: Annotated[RateService, Depends(get_rate_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> DollarRateRead:
        rate = service.refresh_from_bcv()
        return DollarRateRead.model_validate(rate)

    @app.put("/api/rate", response_model=DollarRateRead, tags=["tasa"])
    def set_manual_rate(
        data: ManualRateCreate,
        service: Annotated[RateService, Depends(get_rate_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> DollarRateRead:
        rate = service.set_manual(data.value)
        return DollarRateRead.model_validate(rate)

    @app.get("/api/rate/bcv", response_model=list[BcvCurrencyRead], tags=["tasa"])
    def bcv_rates(
        service: Annotated[CurrencyService, Depends(get_currency_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> list[BcvCurrencyRead]:
        return [
            BcvCurrencyRead(name=name, value=value)
            for name, value in service.bcv_rates()
        ]

    @app.get(
        "/api/rate/alternates",
        response_model=list[AlternateCurrencyRead],
        tags=["tasa"],
    )
    def list_alternates(
        service: Annotated[CurrencyService, Depends(get_currency_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> list[AlternateCurrencyRead]:
        return [
            AlternateCurrencyRead.model_validate(currency)
            for currency in service.list_alternates()
        ]

    @app.put(
        "/api/rate/alternates",
        response_model=list[AlternateCurrencyRead],
        tags=["tasa"],
    )
    def set_alternates(
        data: list[AlternateCurrencyCreate],
        service: Annotated[CurrencyService, Depends(get_currency_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> list[AlternateCurrencyRead]:
        currencies = service.replace_alternates(
            [(item.name, item.value, item.source) for item in data]
        )
        return [AlternateCurrencyRead.model_validate(currency) for currency in currencies]

    @app.patch(
        "/api/rate/alternates/{currency_id}",
        response_model=AlternateCurrencyRead,
        tags=["tasa"],
    )
    def update_alternate(
        currency_id: int,
        data: AlternateCurrencyValueUpdate,
        service: Annotated[CurrencyService, Depends(get_currency_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> AlternateCurrencyRead:
        currency = service.update_value(currency_id, data.value)
        return AlternateCurrencyRead.model_validate(currency)

    @app.delete(
        "/api/rate/alternates/{currency_id}",
        status_code=status.HTTP_204_NO_CONTENT,
        tags=["tasa"],
    )
    def delete_alternate(
        currency_id: int,
        service: Annotated[CurrencyService, Depends(get_currency_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
    ) -> None:
        service.delete(currency_id)

    @app.get(
        "/api/projections/{product_id}",
        response_model=list[ProjectionPointRead],
        tags=["proyecciones"],
    )
    def project(
        product_id: int,
        service: Annotated[ProjectionService, Depends(get_projection_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
        movement: MovementType = MovementType.SALE,
        periods: int = Query(default=6, ge=1, le=36),
        strategy: str = "moving_average",
    ) -> list[ProjectionPoint]:
        return service.project(product_id, movement, periods, strategy)

    @app.get(
        "/api/statistics/descriptive",
        response_model=DescriptiveStatisticsRead,
        tags=["estadisticas"],
    )
    def descriptive_statistics(
        service: Annotated[StatisticsService, Depends(get_statistics_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
        category: str | None = None,
    ) -> DescriptiveStatisticsRead:
        report = service.descriptive_report(category=category)
        return DescriptiveStatisticsRead.model_validate(report)

    @app.get(
        "/api/statistics/export",
        tags=["estadisticas"],
    )
    def export_statistics(
        service: Annotated[StatisticsService, Depends(get_statistics_service)],
        _current_user: Annotated[User, Depends(get_current_user)],
        format: str = Query(default="xlsx", pattern="^(xlsx|csv)$"),
        category: str | None = None,
    ) -> Response:
        if format == "csv":
            payload = service.export_csv(category=category)
            csv_disp = 'attachment; filename="estadisticas_inventario_marcano.csv"'
            return Response(
                content=payload,
                media_type="text/csv; charset=utf-8",
                headers={"Content-Disposition": csv_disp},
            )
        payload = service.export_excel(category=category)
        xlsx_disp = 'attachment; filename="estadisticas_inventario_marcano.xlsx"'
        return Response(
            content=payload,
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": xlsx_disp},
        )

    return app


app = create_app()


def run() -> None:
    uvicorn.run("marcano.api:app", host="127.0.0.1", port=8000, reload=True)
