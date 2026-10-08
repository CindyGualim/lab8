# Ejercicio 1 – Preparación del ambiente

## Estructura del proyecto y propósito de cada directorio

| Ruta | Propósito |
|---|---|
| `data/raw/` | Datos **tal como se descargan** de la TLC, organizados como `<tipo>/<año>/<archivo>.parquet`. Nunca se modifican: son la fuente de verdad y se pueden regenerar con el script de descarga. Están excluidos de Git (`.gitignore`). |
| `data/processed/` | Datos **derivados** del análisis: la base `.duckdb` materializada (Ejercicio 6), tablas limpias o agregadas, exportaciones. También excluidos de Git porque se regeneran con los scripts. |
| `notebooks/` | Notebooks de Jupyter para la exploración interactiva y la presentación de resultados (tablas y gráficas). |
| `scripts/` | Código Python reproducible y ejecutable por línea de comandos: descarga de datos, ejecución de consultas SQL, benchmarks. |
| `sql/` | Consultas SQL versionadas, una por archivo/ejercicio. Son la fuente única de las consultas; notebooks y scripts las leen de aquí. |
| `docs/` | Documentación del análisis: explicación de las consultas, decisiones tomadas, resultados (`docs/resultados/`) y respuestas a las preguntas del laboratorio. |
| `Dockerfile` | Imagen del servicio `lab`: Python 3.11 con DuckDB, JupyterLab, pandas, pyarrow, matplotlib y requests en versiones fijas (`requirements.txt`). |
| `metabase.Dockerfile` | Imagen del servicio `metabase` (herramienta de tableros) con el driver de DuckDB instalado. |
| `docker-compose.yml` | Define y conecta los dos servicios, sus puertos y los volúmenes que montan las carpetas del proyecto dentro de los contenedores. |
| `requirements.txt` | Versiones exactas de las librerías de Python. |
| `README.md` | Instrucciones para reproducir el proyecto. |

La separación `raw` / `processed` hace que cualquier resultado pueda rastrearse
hasta los archivos originales, y la separación entre `sql/`, `scripts/` y
`notebooks/` permite reutilizar la misma consulta desde varias herramientas.

## 1.1 – 1.2 Fork, clonación y levantamiento

- Repositorio del docente (upstream): <https://github.com/menene/duckdb>
- Fork del equipo (origin): <https://github.com/CindyGualim/lab8>

```bash
git clone https://github.com/CindyGualim/lab8.git
cd lab8
git remote add upstream https://github.com/menene/duckdb.git
docker compose up --build -d
```

La primera construcción descarga las imágenes base, Metabase (~500 MB) y las
librerías de Python; tomó algunos minutos. Las siguientes veces basta con
`docker compose up -d`.

## 1.3 Verificación de los servicios

| Servicio | Contenedor | URL | Verificación | Resultado |
|---|---|---|---|---|
| JupyterLab | `lab8-lab` | <http://127.0.0.1:8888> | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8888/lab` | `200` |
| Metabase | `lab8-metabase` | <http://127.0.0.1:3000> | `curl -s http://127.0.0.1:3000/api/health` | `{"status":"ok"}` |

Además:

- `docker compose ps` muestra ambos contenedores en estado `Up`.
- En los logs de Metabase aparece `Registered driver :duckdb`, es decir, el
  driver de DuckDB quedó cargado (`docker compose logs metabase | grep -i duckdb`).
- Dentro de `lab` se ejecutaron con éxito el script de descarga y las consultas
  del Ejercicio 3 (`docker compose exec lab python scripts/run_sql.py sql/ex3_exploracion.sql`),
  lo que confirma que DuckDB lee los Parquet montados en `/workspace/data`.

Los puertos están ligados a `127.0.0.1`, por lo que los servicios solo son
accesibles desde la máquina local. JupyterLab se ejecuta sin token (ambiente
local de laboratorio).

## 1.4 Herramientas disponibles en el ambiente

Obtenidas con `docker compose exec lab sh -c "python --version; pip list"` y
`docker compose exec metabase java -version`:

**Servicio `lab`** (imagen `python:3.11.14-slim`)

| Herramienta | Versión | Uso en el laboratorio |
|---|---|---|
| Python | 3.11.14 | Lenguaje de los scripts y notebooks |
| duckdb (librería Python) | 1.5.5 | Motor SQL analítico; consulta Parquet y crea bases `.duckdb` |
| JupyterLab | 4.6.4 | Notebooks interactivos (puerto 8888) |
| pandas | 3.0.6 | Recibir resultados de DuckDB (`.df()`) para mostrarlos/graficarlos |
| pyarrow | 25.0.1 | Formato Arrow/Parquet, intercambio eficiente con DuckDB y pandas |
| matplotlib | 3.11.2 | Visualizaciones |
| requests | 2.34.2 | Descargas HTTP desde la TLC |
| curl | (sistema) | Pruebas HTTP manuales |

No se instala el CLI `duckdb`; DuckDB se usa como librería desde Python.

**Servicio `metabase`** (imagen `eclipse-temurin:21-jre-jammy`)

| Herramienta | Versión |
|---|---|
| Java (OpenJDK) | 21 |
| Metabase | v0.63.19 |
| Driver DuckDB para Metabase | 1.5.5.0 (alineado con duckdb 1.5.5) |

Metabase es la herramienta de visualización/tableros del Ejercicio 7. Monta la
misma carpeta `data/` en `/workspace/data`; al conectarse a una base `.duckdb`
debe hacerlo en modo `read_only` para no bloquear al servicio `lab`.

## 1.6 ¿Por qué es importante un ambiente reproducible?

- **Mismos resultados en cualquier máquina.** Las versiones de Python, DuckDB,
  pandas y Metabase están fijadas en `requirements.txt` y en los Dockerfiles. Un
  cambio de versión puede alterar resultados (p. ej. tipos inferidos al leer
  Parquet, funciones SQL nuevas o con otro comportamiento) o romper la
  compatibilidad entre el driver de Metabase y el archivo `.duckdb`.
- **Elimina el "en mi máquina sí funciona".** Cualquier integrante o el docente
  levanta el ambiente con un solo comando, sin instalar nada aparte de Docker.
  En este equipo, por ejemplo, la instalación local de Windows no tenía DuckDB;
  dentro del contenedor todo estaba disponible.
- **Rutas consistentes.** Dentro de los contenedores los datos siempre están en
  `/workspace/data`, independientemente del sistema operativo del anfitrión.
- **Trazabilidad.** El código, las consultas y la definición del ambiente están
  versionados; los datos se regeneran con los scripts. Así cualquier resultado
  se puede volver a obtener desde cero y auditar.
- **Aislamiento.** Las dependencias del laboratorio no interfieren con las de
  otros proyectos ni con el sistema operativo.
