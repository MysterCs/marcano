# Marcano Flutter

Cliente Flutter para el inventario y las proyecciones de Marcano. Consume la API FastAPI incluida en el directorio raiz del repositorio. Incluye registro, inicio de sesion, almacenamiento seguro de la sesion y un diseno adaptable para telefonos y web.

## Ejecutar

Desde la raiz del proyecto, iniciar primero `main.py`. Despues, en este directorio:

```powershell
..\scripts\flutter.cmd run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Para Windows se requiere Visual Studio con `Desktop development with C++`; para Android se requiere Android SDK.

## Validar

```powershell
..\scripts\flutter.cmd analyze
..\scripts\flutter.cmd test
..\scripts\flutter.cmd build web --release
```

La arquitectura y los demas comandos estan documentados en `../README.md`.
