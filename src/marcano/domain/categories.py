from __future__ import annotations

import re
import unicodedata

DEFAULT_CATEGORY = "Otros / General"

CATEGORY_RULES: tuple[tuple[str, tuple[str, ...]], ...] = (
    (
        "Patch Cords y Pig Tails",
        ("PATCH", "PIG TAIL", "PIGTAIL", "PIG ", "JUMP"),
    ),
    (
        "Racks, Bandejas y Gabinetes",
        (
            "BANDEJA",
            "RACK",
            "GABINETE",
            "ORGANIZADOR",
            "ORG.",
            "CAJA",
            "TAPA",
            "PANEL",
            "ODF",
        ),
    ),
    (
        "Equipos Activos y Red",
        (
            "SWITCH",
            "ROUTER",
            "CONVERTIDOR",
            "TRANSCEIVER",
            "SFP",
            "MODULO",
            "MEDIA CONVERTER",
            "ONU",
            "OLT",
            "ANTENA",
            "MIKROTIK",
            "TRANSCEPTOR",
        ),
    ),
    (
        "Fibra Óptica y Empalmes",
        (
            "SPLITTER",
            "ATENUADOR",
            "EMPALME",
            "MANGA",
            "ACOPLADOR",
            "COUPLER",
            "ADAPTADOR",
            "F.O",
            "FIBRA",
            "OPTICA",
            "OPTICO",
            "FTTH",
        ),
    ),
    (
        "Cableado y Conectividad",
        (
            "CABLE",
            "CONECTOR",
            "JACK",
            "FACEPLATE",
            "FACE PLATE",
            "FACE ",
            "PLUG",
            "RJ-45",
            "RJ45",
            "UTP",
            "HEMBRA/HEMBRA",
            "COAXIAL",
        ),
    ),
    (
        "Canalización y Herrajes",
        (
            "CANALETA",
            "ESQUINA",
            "ANGULO",
            "HERRAJE",
            "ESCALERILLA",
            "PLACA",
            "ARGOLLA",
            "HEBILLA",
            "FLEJE",
            "TIEWRAP",
            "TIE WRAP",
            "TIE ",
            "AMARRA",
            "ABRAZADERA",
            "TORNILLO",
            "TUERCA",
            "RAMPLUG",
            "SOPORTE",
            "RIEL",
        ),
    ),
    (
        "Energía y Respaldo",
        (
            "BATERIA",
            "FUENTE",
            "UPS",
            "INVERSOR",
            "REGULADOR",
            "CARGADOR",
            "REGLETA",
            "BREAKER",
            "TRANSFORMADOR",
        ),
    ),
    (
        "Herramientas y Consumibles",
        (
            "ETIQUETA",
            "KIT",
            "PELA",
            "CORTADORA",
            "MEDIDOR",
            "LIJA",
            "PEGAMENTO",
            "ACELERADOR",
            "TOALLITA",
            "ALCOHOL",
            "CINTA",
            "PINZA",
            "DESTORNILLADOR",
            "DISCO",
            "BROCA",
            "ROLLO",
            "LIMPIADOR",
        ),
    ),
)

ALL_CATEGORIES: tuple[str, ...] = tuple(name for name, _ in CATEGORY_RULES) + (DEFAULT_CATEGORY,)


def _normalize(text: str) -> str:
    decomposed = unicodedata.normalize("NFD", text.upper())
    without_accents = "".join(ch for ch in decomposed if unicodedata.category(ch) != "Mn")
    collapsed = re.sub(r"\s+", " ", without_accents).strip()
    return f" {collapsed} "


def infer_category(product_name: str | None) -> str:
    """Infiere la categoria del producto a partir de su nombre."""
    if not product_name or not product_name.strip():
        return DEFAULT_CATEGORY

    normalized = _normalize(product_name)
    for category, keywords in CATEGORY_RULES:
        for keyword in keywords:
            if keyword in normalized:
                return category

    if " FO " in normalized:
        return "Fibra Óptica y Empalmes"

    return DEFAULT_CATEGORY
