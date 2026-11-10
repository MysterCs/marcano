# Marcano Inventario

Base de una aplicacion multiplataforma para seguimiento de inventario y proyeccion mensual de ventas y compras.

## Arquitectura

- **Flutter/Dart**: cliente para Android, iOS, Windows, macOS, Linux y web.
- **Python/FastAPI**: API REST y reglas de negocio.
- **PostgreSQL/SQLAlchemy**: base `marcano` para la aplicacion; SQLite se usa en pruebas aisladas.
- **pandas/numpy**: agregacion mensual y algoritmos de proyeccion.
- **JavaScript**: utilidades de formato para reportes en la version web de Flutter.

El cliente no accede directamente a la base de datos: se comunica con el backend mediante HTTP.

## Interfaz

- **Modo oscuro global**: paleta en negro, rojo, naranja y azul con Material 3.
- **Listado paginado**: el dashboard muestra 25 productos por pagina; el resto se navega con los botones de paginacion.
- **Widget de producto**: cada tarjeta tiene un boton que abre la informacion completa del producto en un panel inferior. Desde ahi puedes editar nombre, modelo, existencias, stock minimo, punto, unidad, estado, coste y precio de venta, y guardar los cambios con `PATCH /api/products/{id}`.
- **Auditoria de modificaciones**: el backend guarda que usuario hizo la ultima edicion (`updated_by_user_name`, `updated_at`) y el widget lo muestra.
- **Boton de billete**: en la barra principal, junto al boton de cerrar sesion, hay un boton con forma de billete que muestra la tasa del dolar registrada para el sistema al pulssarlo (origen y fecha incluidos).
- **Tasa del sistema**: la tasa del dolar se obtiene del BCV o se configura manual en `Ajustes`.
- **Monedas alternas**: en `Ajustes`, `Monedas alternas del sistema` abre un selector con todas las divisas publicadas por el BCV (dolar, euro, yuan, rublo, lira...). Puedes elegir una o varias monedas alternas; cada una guarda su propia tasa. Tambien puedes agregar monedas con el nombre que quieras y una tasa manual, editar la tasa o quitar una moneda.
- **Ajustes en subsecciones**: Ajustes se organiza en tres grupos. `Inventario` (productos por pagina del listado, se guarda en el dispositivo), `Tasa` (tasa del dolar y monedas alternas) y `General` (estado del sistema y cuenta). La tarjeta `Tasa del dolar` ya no aparece en el inventario; la tasa se consulta desde el boton de billete de la barra superior o en Ajustes.

## Ejecutable

Puedes iniciar el aplicativo desde `MarcanoControl.exe` en la raiz del proyecto. El panel permite iniciar, pausar/reanudar, detener y abrir los logs y la aplicacion web. Los logs se guardan en `data\logs\aplicativo.log`. Para reconstruir el ejecutable y la version web:
```powershell
scripts\build_launcher.ps1
```


## Estructura

```text
marcano/
├─ src/marcano/
│  ├─ domain/                 # Entidades, movimientos y errores de negocio
│  ├─ infrastructure/         # SQLAlchemy, tablas y conexion
│  ├─ repositories/           # Contrato y repositorio concreto
│  ├─ services/               # Inventario y estrategias de proyeccion
│  ├─ factories/              # RepositoryFactory y ProjectionFactory
│  ├─ api.py                  # Endpoints FastAPI
│  ├─ config.py               # Variables de entorno
│  └─ schemas.py              # DTO de entrada y salida
├─ flutter_app/
│  ├─ lib/
│  │  ├─ core/auth/           # Sesion, acceso y cierre automatico
│  │  ├─ core/factories/      # RepositoryFactory del cliente
│  │  ├─ domain/repositories/ # Contratos de inventario y autenticacion
│  │  ├─ data/
│  │  │  ├─ models/           # DTO del cliente
│  │  │  ├─ repositories/     # Implementacion remota
│  │  │  └─ services/         # Cliente HTTP
│  │  ├─ presentation/pages/  # Acceso, registro, inventario y proyecciones
│  │  ├─ presentation/widgets/# Diseno adaptable de autenticacion
│  │  └─ main.dart
│  ├─ test/                   # Pruebas Dart/Flutter
│  ├─ test_js/                # Pruebas de utilidades JavaScript
│  └─ web/js/                 # Factory de formateadores web
├─ tests/                     # Pruebas del backend
├─ data/                      # Excel de origen y cluster PostgreSQL (no se versiona)
├─ scripts/                   # Gestion de PostgreSQL, Flutter e importacion Excel
├─ main.py                    # Arranque de la API
├─ requirements.txt
├─ requirements-dev.txt
└─ pyproject.toml
```

## Patron Factory

| Fabrica | Responsabilidad | Implementaciones iniciales |
|---|---|---|
| Python `RepositoryFactory` | Seleccionar persistencia | PostgreSQL y SQLite con SQLAlchemy |
| Python `ProjectionFactory` | Seleccionar algoritmo | Media movil y tendencia lineal |
| Dart `RepositoryFactory` | Seleccionar origen de datos | API remota |
| JS `ReportFormatterFactory` | Seleccionar formato | Moneda, numero y porcentaje |

Para anadir otro motor, otro algoritmo o un repositorio simulado se registra una nueva implementacion en la fabrica correspondiente; las pantallas y los casos de uso no cambian.

## Base de datos PostgreSQL

Configuracion creada para desarrollo local:

| Parametro | Valor |
|---|---|
| Motor | PostgreSQL 18.6 |
| Base | `marcano` |
| Usuario | `admin` |
| Clave | `admin` |
| Host | `127.0.0.1` |
| Puerto | `5433` |
| URL | `postgresql+psycopg://admin:admin@127.0.0.1:5433/marcano` |

Se usa 5433 para no interferir con el PostgreSQL de WSL que ya escucha en 5432. La URL esta en `.env`; `.env.example` solo sirve como plantilla. Las credenciales `admin/admin` son exclusivamente para desarrollo y deben sustituirse en produccion.

Gestion del servidor local:

```powershell
scripts\db.cmd status
scripts\db.cmd start
scripts\db.cmd stop
```

El cluster esta en `data/postgresql` y el binario en `.tools/postgresql`; ambos quedan fuera de control de versiones. El servidor de WSL no fue modificado.

### Importacion de Excel

Fuentes configuradas por defecto:

- `data/INVENTARIO ACTUAL.xlsx`
- `data/ROTACION DE INVENTARIO.xlsx`

Para crear el esquema o repetir una importacion sin duplicar movimientos:

```powershell
.\.venv\Scripts\python.exe scripts\import_excel.py
```

Resultado verificado: **1.386 productos actuales**, **42 productos historicos** y **11.181 movimientos**, con 453.259 entradas y -375.492 salidas, exactamente igual que los totales del libro. Las cabeceras repetidas, filas vacias y subtotales no se importan.

Tablas:

- `products`: codigo/SKU, descripcion, modelo, punto, stock, unidad, estado y costos.
- `inventory_movements`: fecha, tipo de operacion, documento, linea, usuario, cliente/proveedor, almacen, entradas, salidas, costo y fila de origen.
- `sales` y `purchases`: movimientos nuevos registrados desde la API.
- `dollar_rates`: historico de la tasa del dolar registrada para el sistema (BCV o manual).
- `alternate_currencies`: monedas alternas del sistema, cada una con su propia tasa.

Para las proyecciones, `NENT` y `FACT` alimentan el historial de ventas; `NREC` y `COMP` alimentan compras. Ajustes (`AJUE`, `AJUS`) y devoluciones (`DCLI`) se conservan en la base sin mezclarlos con esos dos historiales. El costo del producto se inicializa con su ultimo movimiento disponible porque el inventario actual no incluye una columna de costo.

## Backend

El entorno `.venv` ya esta utilizado por el proyecto. Para reproducir la instalacion:

```powershell
py -3.10 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m pip install -e . --no-deps
Copy-Item .env.example .env
```

Arranque:

```powershell
.\.venv\Scripts\python.exe main.py
```

- API: <http://127.0.0.1:8000/api/health>
- Documentacion interactiva: <http://127.0.0.1:8000/docs>
- Base de datos: PostgreSQL `marcano` en `127.0.0.1:5433` (el esquema se crea automaticamente).

Endpoints:

| Metodo | Ruta | Uso |
|---|---|---|
| POST | `/api/auth/register` | Crear una cuenta |
| POST | `/api/auth/login` | Iniciar sesion y obtener un token JWT |
| GET | `/api/auth/me` | Consultar el usuario autenticado |
| GET | `/api/products` | Listar productos |
| POST | `/api/products` | Crear producto |
| POST | `/api/products/{id}/sales` | Registrar venta y descontar stock |
| POST | `/api/products/{id}/purchases` | Registrar compra y aumentar stock |
| GET | `/api/inventory/summary` | Resumen y alertas de stock |
| GET | `/api/projections/{id}` | Proyectar ventas o compras |
| GET | `/api/rate/bcv` | Divisas publicadas por el BCV |
| GET | `/api/rate/alternates` | Monedas alternas registradas |
| PUT | `/api/rate/alternates` | Reemplazar las monedas alternas |
| PATCH | `/api/rate/alternates/{id}` | Editar la tasa manual de una moneda |
| DELETE | `/api/rate/alternates/{id}` | Quitar una moneda alterna |

Los endpoints de inventario, ventas, compras y proyecciones requieren el encabezado `Authorization: Bearer <token>`. Registro, acceso y salud del servicio son publicos.

## Autenticacion

La tabla `users` guarda `full_name`, `cedula` (unica y como texto), `password_hash`, estado y fecha de creacion. La contrasena nunca se almacena ni se devuelve en texto plano: se procesa con Argon2id. El registro admite contrasenas desde **3 caracteres** y, desde Flutter, inicia la sesion automaticamente despues de crear la cuenta.

El token JWT dura 480 minutos por defecto. `MARCANO_JWT_SECRET_KEY`, `MARCANO_JWT_ALGORITHM` y `MARCANO_JWT_EXPIRATION_MINUTES` permiten configurarlo en `.env`; la clave incluida en el codigo es solo para desarrollo y debe sustituirse por una clave aleatoria privada en cualquier entorno compartido o de produccion.

Flutter guarda el token con `flutter_secure_storage`, lo restaura al abrir la aplicacion y cierra la sesion si la API responde `401`. En web, el almacenamiento seguro requiere un contexto seguro: HTTPS o `localhost`.

## Flutter

El SDK y Git portatil se instalan localmente en `.tools`, ignorado por Git. Versiones validadas: **Flutter 3.47.9**, **Dart 3.13.7** y **DevTools 2.60.0**. El comando `scripts\flutter.cmd` configura el `PATH` y `PUB_CACHE` solo para cada ejecucion, sin cambiar la configuracion global de Windows.

```powershell
scripts\flutter.cmd doctor
cd flutter_app
..\scripts\flutter.cmd create .
..\scripts\flutter.cmd pub get
..\scripts\flutter.cmd run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

`flutter create .` genera los directorios nativos que falten. Tambien se puede ejecutar con `-d chrome` o en un dispositivo configurado. Compilar para Windows requiere Visual Studio con la carga de trabajo de escritorio C++; Android requiere Android SDK.

Para el emulador de Android se usa normalmente:

```powershell
..\scripts\flutter.cmd run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Android tiene habilitado HTTP para el desarrollo local; en produccion se debe usar HTTPS y retirar `usesCleartextTraffic` del manifiesto.

En un dispositivo fisico, usar la IP local del equipo y arrancar la API con una direccion accesible en la red:

```powershell
.\.venv\Scripts\python.exe -m uvicorn marcano.api:app --host 0.0.0.0 --port 8000
```

## Pruebas y calidad

```powershell
# Backend
.\.venv\Scripts\python.exe -m pytest --cov=src/marcano
.\.venv\Scripts\python.exe -m ruff check src tests main.py

# Flutter
cd flutter_app
..\scripts\flutter.cmd analyze
..\scripts\flutter.cmd test

# JavaScript (sin dependencias npm externas)
npm test
```

## Alcance de esta base

Incluye el panel de control ejecutable, persistencia, autenticacion, operaciones de inventario, API, cliente Flutter, proyecciones mensuales y pruebas. Los roles, la sincronizacion sin conexion, las migraciones Alembic y los reportes graficos quedan como siguientes incrementos, no como funciones ya terminadas.

