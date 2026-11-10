import argparse
from pathlib import Path

import uvicorn
from fastapi.staticfiles import StaticFiles

from marcano.api import app


def main() -> None:
    parser = argparse.ArgumentParser(description="Sirve la API y la aplicacion web de Marcano.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--web-root", type=Path, required=True)
    args = parser.parse_args()

    if not (args.web_root / "index.html").is_file():
        raise SystemExit(f"No se encontro la aplicacion web compilada en {args.web_root}.")

    app.mount(
        "/app",
        StaticFiles(directory=args.web_root, html=True),
        name="flutter_web",
    )

    @app.get("/")
    async def index():
        from fastapi.responses import RedirectResponse
        return RedirectResponse(url="/app/")

    uvicorn.run(app, host=args.host, port=args.port, log_level="info")


if __name__ == "__main__":
    main()
