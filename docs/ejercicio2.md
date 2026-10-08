# Ejercicio 2 – Sistema de descarga

Script: [`scripts/download_data.py`](../scripts/download_data.py)

## 2.1 Análisis del script proporcionado

El script original ya sabía descargar un mes, reintentar ante fallos, escribir
sobre un archivo temporal `.part` y omitir archivos existentes. Sus limitaciones:

| Parte | Problema | ¿Modificar? |
|---|---|---|
| `ANIO = 2026` (constante global usada por `construir_nombre`, `construir_url`, `ruta_destino` y `descargar`) | El año estaba fijo; incorporar 2024 y 2025 (Ejercicios 5 y 8) obligaba a editar o duplicar el script. | Sí |
| `DIR_DESTINO = Path("data/raw")` | Ruta relativa al **directorio actual**: ejecutado desde `scripts/` o desde otra carpeta creaba `scripts/data/raw/...` fuera de la estructura del proyecto. | Sí |
| `esta_publicado()` | Hacía `HEAD` pero descartaba el `Content-Length`, que es justo lo que permite saber si la descarga quedó completa. | Sí |
| `descargar_archivo()` | Solo verificaba que se escribiera más de 0 bytes. Si la conexión se cortaba sin error HTTP, un archivo truncado se renombraba como `.parquet` válido. | Sí |
| Verificación | No había forma de comprobar el estado del conjunto descargado sin volver a descargar. | Sí (nuevo modo) |
| Reintentos, `.part`, omisión de existentes, resumen | Correctos. | No |

## 2.2 – 2.6 Cambios realizados

1. **Años parametrizables.** `ANIO` se reemplazó por la tupla `ANIOS = (2026,)`
   y todas las funciones reciben `anio` como parámetro. Se agregó la opción
   `--anio` (acepta varios: `--anio 2024 2026`). Para incorporar un año basta con
   agregarlo a `ANIOS` o pasarlo por línea de comandos; el resto del flujo no cambia.
2. **Rutas absolutas desde la ubicación del script.**
   `RAIZ_PROYECTO = Path(__file__).resolve().parent.parent` y
   `DIR_DESTINO = RAIZ_PROYECTO / "data" / "raw"`. El script guarda siempre en
   `data/raw/<tipo>/<año>/` sin importar desde dónde se ejecute (Windows,
   `scripts/`, o `/workspace` en el contenedor).
3. **Tamaño esperado.** `esta_publicado()` pasó a ser `tamanio_publicado()`:
   devuelve el `Content-Length` del servidor, o `None` si el mes no está
   publicado (la TLC responde `403` para meses inexistentes).
4. **Validación de integridad al descargar.** `descargar_archivo()` compara los
   bytes escritos contra el `Content-Length` y valida la firma Parquet
   (`PAR1` al inicio y al final del archivo, función `es_parquet_valido()`).
   Si algo falla, borra el `.part` y reintenta; el archivo final solo aparece
   cuando está completo.
5. **Modo `--verificar`.** No descarga nada: para cada tipo/año/mes compara
   el archivo local con el servidor y reporta `OK`, `FALTA` (publicado pero no
   descargado), `DIFERENTE` (tamaño distinto o firma inválida) o `---` (no
   publicado). Termina con código 1 si hay problemas, por lo que sirve en
   automatizaciones.
6. **No volver a descargar (2.4).** Se conserva la regla original: si
   `data/raw/<tipo>/<año>/<archivo>` existe y no está vacío, se omite **sin
   hacer ninguna petición al servidor**.

Uso:

```bash
python scripts/download_data.py                  # años en ANIOS (2026), amarillos y verdes
python scripts/download_data.py --taxi green     # solo un tipo
python scripts/download_data.py --anio 2026      # años explícitos
python scripts/download_data.py --verificar      # comparar local vs. servidor
```

Dentro del contenedor: `docker compose exec lab python scripts/download_data.py`.

## 2.5 Ejecución

Primera ejecución (8 oct 2026):

```text
=== YELLOW 2026 ===
  2026-01  descargando (61.2 MiB)...
  2026-01  listo (61.2 MiB) -> data/raw/yellow/2026/yellow_tripdata_2026-01.parquet
  ...
  2026-08  listo (56.3 MiB) -> data/raw/yellow/2026/yellow_tripdata_2026-08.parquet
  2026-09  aun no publicado por la TLC
  ...
=== GREEN 2026 ===
  2026-01  listo (968.4 KiB) -> data/raw/green/2026/green_tripdata_2026-01.parquet
  ...
RESUMEN
  descargados   : 16
  ya existian   : 0
  no publicados : 8
      yellow 2026-09 … 2026-12, green 2026-09 … 2026-12
  fallidos      : 0
```

Segunda ejecución (local y dentro del contenedor) — no descarga nada:

```text
  descargados   : 0
  ya existian   : 16
  no publicados : 8
  fallidos      : 0
```

Estructura resultante:

```text
data/raw/
├── green/2026/green_tripdata_2026-01.parquet … green_tripdata_2026-08.parquet   (8 archivos, 7.9 MiB)
└── yellow/2026/yellow_tripdata_2026-01.parquet … yellow_tripdata_2026-08.parquet (8 archivos, 487.8 MiB)
```

`git status` no muestra ningún archivo de `data/`: el `.gitignore` los excluye.

## 2.7 ¿Cómo se determinó que el conjunto descargado está completo?

Se verificó en tres niveles:

1. **Qué meses existen.** El script no supone los meses: consulta con `HEAD`
   los 12 meses del año. Enero–agosto 2026 responden `200`; septiembre–diciembre
   responden `403` (aún no publicados; la TLC publica con ~2 meses de atraso, el
   archivo de agosto tiene `Last-Modified: 1 oct 2026`). Por lo tanto el conjunto
   esperado hoy es **8 meses × 2 tipos = 16 archivos**.
2. **Cada archivo está íntegro.** `python scripts/download_data.py --verificar`
   compara byte a byte el tamaño local con el `Content-Length` del servidor y
   valida la firma Parquet:

   ```text
   archivo                                     local     servidor  estado
   yellow_tripdata_2026-01.parquet          64165080     64165080  OK
   ...
   yellow_tripdata_2026-09.parquet                 -            -  ---
   green_tripdata_2026-08.parquet            1007530      1007530  OK
   ...
   archivos OK: 16 (495.7 MiB), con problemas: 0
   ```

3. **DuckDB puede leer todo.** Las consultas Q3.1–Q3.2 del Ejercicio 3 abren
   los 16 archivos sin error; el número de filas que declaran los metadatos
   Parquet (`parquet_file_metadata`) coincide exactamente con el conteo leyendo
   los datos: 29 703 355 viajes amarillos y 337 114 verdes, sin meses vacíos.

Cuando la TLC publique septiembre, basta con volver a ejecutar el script: solo
descargará los archivos nuevos.
