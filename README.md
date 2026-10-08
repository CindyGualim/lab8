# Lab 8 - DuckDB

Repositorio base del laboratorio 8 del curso **CC3084 - Data Science**
(Universidad del Valle de Guatemala, Ciclo 2, 2026).

Este es el repositorio **proporcionado por el docente**. Contiene la estructura
del proyecto, el ambiente de ejecucion basado en Docker y un script que descarga
los datos de **2026**. Todo lo demas debe ser construido por cada equipo.

## Trabajo con fork

El laboratorio se desarrolla y se entrega sobre un **fork** de este repositorio.
No se trabaja directamente sobre el repositorio del docente.

1. Realice un fork de este repositorio:
   <https://github.com/menene/duckdb>

2. Clone **su propio fork** (no el del docente):

   ```bash
   git clone https://github.com/<su-usuario>/duckdb.git
   cd duckdb
   ```

3. Opcional, para recibir correcciones publicadas por el docente:

   ```bash
   git remote add upstream https://github.com/menene/duckdb.git
   git fetch upstream
   ```

Realice commits frecuentes y descriptivos: el historial del repositorio es parte
de la evaluacion. **La entrega del laboratorio es la URL de su fork.**

## Estructura

```text
duckdb/
|
+-- data/
|   +-- raw/
|   +-- processed/
|
+-- notebooks/
|
+-- scripts/
|
+-- sql/
|
+-- docs/
|
+-- Dockerfile
+-- metabase.Dockerfile
+-- docker-compose.yml
+-- README.md
```

## Requisitos

- Docker, con Docker Compose
- Git

La primera construccion del ambiente descarga varios cientos de MB y puede
tardar algunos minutos.

Considere el espacio en disco: las imagenes de Docker ocupan unos 3 GB y los
datos de los tres anios del laboratorio superan 1.5 GB, a los que se suma la
base materializada del Ejercicio 6. Se recomienda tener al menos 10 GB libres.

## Datos

El repositorio incluye `scripts/download_data.py`, que descarga los archivos de
2026 publicados por la TLC (`--help` muestra las opciones disponibles). Los
archivos se guardan en `data/raw/<tipo>/<anio>/`.

La TLC publica cada mes con varias semanas de atraso, por lo que los ultimos
meses de 2026 todavia no existen. El script consulta al servidor que meses estan
publicados, de modo que vuelve a ejecutarse sin problema conforme aparezcan
nuevos archivos.

Los datos descargados **no deben incluirse en el repositorio Git**. El archivo
`.gitignore` ya esta configurado para evitarlo.

Fuente de datos: NYC TLC Trip Record Data
<https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>

Dentro de los contenedores, la carpeta `data/` del proyecto esta montada en
`/workspace/data`. Esa es la ruta que deben usar las herramientas que corren
dentro del ambiente, no la ruta de su computadora.

> **Nota sobre DuckDB:** un archivo `.duckdb` admite un solo proceso con permiso
> de escritura a la vez. Si conecta una herramienta externa a su base de datos,
> use el modo de solo lectura (`read_only`) en esa conexion; de lo contrario los
> demas procesos no podran abrir el archivo.

## Material a entregar

Al finalizar, su fork debe contener:

- el codigo fuente modificado y los scripts de descarga;
- las consultas SQL desarrolladas;
- el notebook o notebooks utilizados;
- la documentacion de las consultas;
- los scripts utilizados para los benchmarks;
- el codigo de los indicadores y visualizaciones;
- el tablero o la evidencia del tablero desarrollado;
- este `README.md`, completado segun la siguiente seccion.

Los archivos de datos descargados **no** deben incluirse.

---

# Documentacion del equipo

Las siguientes secciones deben ser completadas por cada equipo. El README final
debe permitir que una persona que no participo en el desarrollo pueda levantar el
ambiente, descargar los datos, ejecutar el analisis, reproducir los benchmarks y
generar los resultados principales.

Documentacion detallada por ejercicio:

| Ejercicio | Documento |
|---|---|
| 1 - Ambiente y estructura del proyecto | [docs/ejercicio1.md](docs/ejercicio1.md) |
| 2 - Sistema de descarga | [docs/ejercicio2.md](docs/ejercicio2.md) |
| 3 - Consultas directas sobre Parquet | [docs/ejercicio3.md](docs/ejercicio3.md) |
| 4 - Analisis exploratorio | [docs/ejercicio4.md](docs/ejercicio4.md) |
| 5 - Incorporacion de 2024 | [docs/ejercicio5.md](docs/ejercicio5.md) |
| 6 - Parquet versus tablas DuckDB | [docs/ejercicio6.md](docs/ejercicio6.md) |
| 7 - Indicadores y tablero | [docs/ejercicio7.md](docs/ejercicio7.md) |

## Como levantar el ambiente

Requisitos: Docker Desktop (o Docker Engine) con Docker Compose y Git.

1. Clonar el fork y entrar a la carpeta:

   ```bash
   git clone https://github.com/CindyGualim/lab8.git
   cd lab8
   ```

2. Asegurarse de que Docker este corriendo (en Windows/macOS, abrir Docker
   Desktop y esperar a que `docker info` responda sin error).

3. Construir y levantar los servicios en segundo plano:

   ```bash
   docker compose up --build -d
   ```

   La primera vez tarda varios minutos. Despues basta con `docker compose up -d`.

4. Verificar que ambos servicios esten arriba:

   ```bash
   docker compose ps                                   # lab8-lab y lab8-metabase en estado "Up"
   curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8888/lab   # 200
   curl -s http://127.0.0.1:3000/api/health            # {"status":"ok"}
   ```

   | Servicio | URL | Contenido |
   |---|---|---|
   | JupyterLab (`lab`) | <http://127.0.0.1:8888> | Python 3.11, DuckDB 1.5.5, pandas, pyarrow, matplotlib, requests |
   | Metabase | <http://127.0.0.1:3000> | Tableros, con driver de DuckDB 1.5.5.0 |

   Metabase tarda alrededor de un minuto en estar disponible la primera vez.

5. Los comandos del proyecto se ejecutan dentro del contenedor `lab`:

   ```bash
   docker compose exec lab python scripts/download_data.py
   ```

   o desde una terminal de JupyterLab. Dentro del contenedor el proyecto esta en
   `/workspace` y los datos en `/workspace/data`.

6. Para detener el ambiente: `docker compose down` (los datos en `data/` se
   conservan; agregar `-v` borra tambien la configuracion de Metabase).

## Como descargar los datos

```bash
docker compose exec lab python scripts/download_data.py               # amarillos y verdes de 2024, 2025 y 2026
docker compose exec lab python scripts/download_data.py --taxi green  # solo un tipo
docker compose exec lab python scripts/download_data.py --anio 2026   # anios explicitos
docker compose exec lab python scripts/download_data.py --verificar   # comparar local vs. servidor
```

- Los archivos se guardan en `data/raw/<tipo>/<anio>/<archivo>.parquet`.
- Tambien se descarga la tabla de zonas de la TLC en `data/raw/taxi_zone_lookup.csv`
  (traduce `PULocationID` / `DOLocationID` a borough y zona).
- Los anios por defecto estan en la constante `ANIOS` del script.
- El script consulta que meses estan publicados; los que ya existen
  localmente no se vuelven a descargar, por lo que puede ejecutarse cuantas veces
  se quiera.
- Cada descarga se valida contra el tamanio informado por el servidor y la firma
  Parquet. `--verificar` repite esa validacion para todos los archivos y termina
  con codigo 1 si falta o difiere alguno.

Estado al 8 de octubre de 2026: 64 archivos (1.9 GiB): 2024 y 2025 completos y
enero a agosto de 2026 de cada tipo; septiembre a diciembre de 2026 aun no estan
publicados por la TLC.

Cambios realizados al script y verificacion de completitud:
[docs/ejercicio2.md](docs/ejercicio2.md).

## Como ejecutar el analisis

Las consultas estan en `sql/` y se ejecutan con el runner, que guarda la consulta,
su tiempo y su resultado en `docs/resultados/<archivo>.md`:

```bash
# Ejercicio 3: exploracion directa sobre los archivos Parquet
docker compose exec lab python scripts/run_sql.py sql/ex3_exploracion.sql

# Ejercicio 4: analisis exploratorio
docker compose exec lab python scripts/run_sql.py sql/ex4_analisis.sql

# Ejercicio 5: validacion de la incorporacion de 2024
docker compose exec lab python scripts/run_sql.py sql/ex5_validacion.sql
```

`--salida <nombre>` cambia el archivo de resultados (por ejemplo, para correr las
consultas de un ejercicio anterior sobre todos los anios sin sobrescribir sus
resultados originales):

```bash
docker compose exec lab python scripts/run_sql.py sql/ex4_analisis.sql --salida ex4_analisis_2024_2026
```

Los notebooks `notebooks/ex3_exploracion.ipynb` y `notebooks/ex4_analisis.ipynb`
ejecutan las mismas consultas de los archivos SQL; el del Ejercicio 4 genera
ademas las graficas en `docs/img/`. Para regenerarlos con salidas:

```bash
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/ex3_exploracion.ipynb
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/ex4_analisis.ipynb
```

## Como reproducir los benchmarks

```bash
docker compose stop metabase        # libera memoria y el archivo taxis.duckdb
docker compose exec lab python scripts/benchmark.py
```

Para 1 mes, 1 anio, 2 anios y 3 anios de datos crea una base DuckDB, ejecuta las
consultas de `sql/ex6_benchmark.sql` sobre los Parquet y sobre la tabla (mediana
de 3 ejecuciones) y escribe la tabla de tiempos en `docs/resultados/ex6_benchmark.md`.
Al terminar deja la base completa en `data/processed/taxis.duckdb`. Detalle y
analisis en [docs/ejercicio6.md](docs/ejercicio6.md).

## Como generar los resultados principales

<!-- TODO -->
