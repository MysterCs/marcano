class DomainError(Exception):
    """Error de negocio presentable al usuario."""


class ProductNotFoundError(DomainError):
    pass


class DuplicateSKUError(DomainError):
    pass


class InsufficientStockError(DomainError):
    pass


class DuplicateCedulaError(DomainError):
    pass


class AuthenticationError(DomainError):
    pass


class InvalidSessionError(DomainError):
    pass


class RateUnavailableError(DomainError):
    """No se pudo obtener la tasa del dolar desde la fuente externa."""
