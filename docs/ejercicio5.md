# Ejercicio 5 – Incorporación de datos de 2024

| Recurso | Ruta |
|---|---|
| Script de descarga | [`scripts/download_data.py`](../scripts/download_data.py) |
| Consultas de validación | [`sql/ex5_validacion.sql`](../sql/ex5_validacion.sql) |
| Resultados de validación | [`docs/resultados/ex5_validacion.md`](resultados/ex5_validacion.md) |
| Consultas del Ej. 3 sobre 2024 + 2026 | [`docs/resultados/ex3_exploracion_2024_2026.md`](resultados/ex3_exploracion_2024_2026.md) |
| Consultas del Ej. 4 sobre 2024 + 2026 | [`docs/resultados/ex4_analisis_2024_2026.md`](resultados/ex4_analisis_2024_2026.md) |

Reproducir:

```bash
docker compose exec lab python scripts/download_data.py              # descarga solo lo que falta
docker compose exec lab python scripts/download_data.py --verificar
docker compose exec lab python scripts/run_sql.py sql/ex5_validacion.sql
docker compose exec lab python scripts/run_sql.py sql/ex3_exploracion.sql --salida ex3_exploracion_2024_2026
docker compose exec lab python scripts/run_sql.py sql/ex4_analisis.sql --salida ex4_analisis_2024_2026
```

## 5.1 Modificación del sistema de descarga

Gracias al cambio del Ejercicio 2 (años parametrizables), incorporar 2024 requirió
modificar **una sola línea** de código:

```diff
-ANIOS = (2026,)
+ANIOS = (2024, 2026)
```

(además de actualizar el docstring). La fuente sigue siendo la original de la TLC
(`https://d37ci6vzurychx.cloudfront.net/trip-data/<tipo>_tripdata_2024-MM.parquet`);
los archivos no los entrega el docente, el script los obtiene directamente. Sin tocar el
código también se podría haber ejecutado `python scripts/download_data.py --anio 2024 2026`.

## 5.2 – 5.4 Ejecución y conservación de 2026

Antes de ejecutar se registró nombre, tamaño y fecha de modificación de los 16 archivos de
2026 (`stat -c '%n %s %Y'`). Luego se ejecutó la descarga dentro del contenedor:

```text
=== YELLOW 2024 ===
  2024-01  descargando (47.6 MiB)...
  2024-01  listo (47.6 MiB) -> data/raw/yellow/2024/yellow_tripdata_2024-01.parquet
  ...
=== YELLOW 2026 ===
  2026-01  ya existe, se omite
  ...
RESUMEN
  descargados   : 24
  ya existian   : 16
  no publicados : 8      (2026-09 a 2026-12 de cada tipo)
  fallidos      : 0
```

Tardó ~1.5 minutos. Resultados:

- **5.2 Se conservan los archivos de 2026:** después de la descarga, el listado de
  nombre/tamaño/fecha de los 16 archivos de 2026 es idéntico al de antes (`diff` sin
  diferencias). El script no los abrió ni los reescribió.
- **5.3 No se vuelve a descargar:** una segunda ejecución reporta
  `descargados: 0, ya existian: 40`.

Estructura resultante:

```text
data/raw/
├── taxi_zone_lookup.csv
├── green/2024/  12 archivos  (15.2 MiB)
├── green/2026/   8 archivos  ( 7.9 MiB)
├── yellow/2024/ 12 archivos  (660.9 MiB)
└── yellow/2026/  8 archivos  (487.8 MiB)
```

## 5.5 Verificación de los nuevos archivos

1. `python scripts/download_data.py --verificar` → **40 archivos OK (1.1 GiB), 0 con
   problemas**: el tamaño de cada archivo coincide con el `Content-Length` del servidor y
   todos tienen la firma Parquet.
2. Las consultas de [`sql/ex5_validacion.sql`](../sql/ex5_validacion.sql):

| Consulta | Objetivo | Resultado |
|---|---|---|
| **Q5.1** Archivos y registros por tipo y año (`parquet_file_metadata`) | Confirmar que DuckDB ve los archivos nuevos | yellow 2024: 12 archivos, 41 169 720 registros · green 2024: 12 archivos, 660 218 registros. 2026 sin cambios (8 + 8 archivos). |
| **Q5.2** Meses esperados vs. presentes (`generate_series` + `LEFT JOIN`) | Detectar meses faltantes o archivos vacíos | 12/12 meses en 2024 y 8/8 en 2026 para ambos tipos; 0 faltantes, 0 vacíos. |
| **Q5.3** Filas según metadatos vs. filas leídas, por mes | Comprobar que cada archivo se lee completo | Diferencia **0** en los 40 meses. |
| **Q5.4** Columnas no presentes en todos los archivos (`parquet_schema`) | Detectar cambios de esquema entre años | Solo `cbd_congestion_fee` (no existe en 2024) y `request_source` (solo desde 2026-06). Ningún tipo físico cambia entre años. |

**Decisión a partir de Q5.4:** `cbd_congestion_fee` no existe en 2024 porque el cobro por
congestión en Manhattan empezó en enero de 2025. Con `union_by_name = true` esos registros
quedan con `NULL`, lo que motivó la corrección descrita en 5.7.

## 5.6 Consulta conjunta de 2024 y 2026

Las mismas vistas (`viajes`, `viajes_validos`) leen ahora los 40 archivos. Q5.5 y Q5.6
comparan **el mismo período (enero–agosto)** de ambos años para no confundir el cambio
entre años con la estacionalidad:

| Tipo | Año | Viajes válidos | Viajes/día | Total prom. | Tarifa mediana | % tarjeta | % sin info. de pago | % con cuota CBD |
|---|---|---|---|---|---|---|---|---|
| yellow | 2024 | 25 421 626 | 104 187 | 28.29 | 13.50 | 76.0 | 9.0 | 0 |
| yellow | 2026 | 28 148 358 | 115 837 | 30.18 | 15.60 | 65.4 | 25.0 | 72.5 |
| green | 2024 | 412 671 | 1 691 | 23.77 | 13.50 | 67.9 | 4.1 | 0 |
| green | 2026 | 319 609 | 1 315 | 25.38 | 13.50 | 65.6 | 14.9 | 8.6 |

Variación 2026 vs. 2024 (Q5.6):

| Tipo | Viajes/día | Total promedio | Tarifa mediana | Velocidad mediana |
|---|---|---|---|---|
| yellow | **+11.2 %** | +6.7 % | +15.6 % | −2.5 % |
| green | **−22.2 %** | +6.8 % | 0 % | −3.2 % |

Las cifras de 2026 de Q5.5 (28 148 358 viajes válidos, total promedio 30.18) son
idénticas a las del Ejercicio 4. Agregar 2024 no alteró los resultados de 2026; solo se
sumaron filas nuevas.

Primeras observaciones que solo aparecen al juntar los años:

- Los taxis amarillos **crecieron** (+11 % de viajes diarios) mientras que los verdes
  **cayeron** (−22 %).
- La tarifa mediana de los amarillos subió 15.6 % (de 13.50 a 15.60 USD) y la de los verdes
  no cambió.
- Los registros **sin información de pago** pasaron de 9 % a 25 % en amarillos y de 4 % a 15 %
  en verdes (Q5.7). El problema de calidad detectado en el Ejercicio 3 es reciente y crece,
  así que cualquier comparación de formas de pago entre años debe controlarlo.
- La exclusión por distancia 0 creció en amarillos (1.05 % → 2.45 %) y los montos negativos
  bajaron (1.57 % → 0.46 %).

## 5.7 ¿Las consultas anteriores necesitan modificarse?

**Prueba realizada:** se ejecutaron los archivos `sql/ex3_exploracion.sql` (18 consultas) y
`sql/ex4_analisis.sql` (14 consultas) **sin modificar** sobre los 40 archivos, guardando la
salida con `--salida` para no sobrescribir los resultados de 2026 que documentan los
ejercicios 3 y 4.

| | Solo 2026 (30.0 M registros) | 2024 + 2026 (71.9 M registros) |
|---|---|---|
| Consultas con error | 0 | **0** |
| Tiempo total Ej. 3 | 16.8 s | 54.2 s |
| Tiempo total Ej. 4 | 47.4 s | 119.4 s |

**Conclusión: no fue necesario reescribir ninguna consulta para que funcionen.** Todas usan
patrones `data/raw/<tipo>/*/*.parquet` y obtienen el año y el mes del nombre del archivo, por
lo que incluyen 2024 automáticamente (p. ej. Q3.1 y Q4.1 ya muestran 2024 como filas nuevas).
El tiempo crece de forma aproximadamente proporcional al volumen (×2.4 datos, ×2.5–3.2 tiempo).

Sin embargo, revisar los resultados mostró **un cambio necesario** y una consideración de
interpretación:

1. **Corrección en la vista `viajes` (único cambio en el SQL anterior).** Con 2024 incluido,
   Q4.11 seguía reportando una cuota CBD promedio de 0.54 USD, pero Q4.12 indicaba que solo el
   30 % de los viajes la pagaba. Las dos cifras se contradecían porque `avg()` ignora los
   `NULL` de 2024 (promediaba solo 2026), mientras que el porcentaje sí contaba los viajes de
   2024. Como la cuota no existía en 2024, `NULL` significa "0 USD cobrados", y la vista ahora
   usa `coalesce(cbd_congestion_fee, 0)`. Después del cambio, Q4.11 da 0.23 USD, coherente con
   el 30 %. En 2026 la columna nunca es `NULL` (verificado), así que los resultados de 2026 no
   cambian. También se agregó la columna `anio` a la vista para facilitar agrupar por año;
   agregar una columna no afecta a las consultas existentes.
2. **Agregados que mezclan años.** Las consultas del Ejercicio 4 que no agrupan por mes
   (Q4.2–Q4.14) ahora promedian 2024 y 2026 juntos. Son correctas, pero responden otra
   pregunta ("en todo el período disponible"). Por ejemplo, en el período completo los viajes
   de aeropuerto representan el 24.9 % de los ingresos amarillos, contra 20.9 % en 2026. Para
   comparar años hay que agrupar por `anio` y usar el mismo rango de meses, como hacen Q5.5 y
   Q5.6. Se dejaron sin cambios porque su objetivo (describir el comportamiento general)
   sigue siendo válido; la comparación por año se integrará en los indicadores (Ejercicios 7 y 8).

Los archivos `docs/resultados/ex3_exploracion.md` y `docs/resultados/ex4_analisis.md`
se conservan como la versión de 2026 que citan los documentos de esos ejercicios.

## 5.8 Consultas usadas para validar la incorporación de 2024

Todas están en [`sql/ex5_validacion.sql`](../sql/ex5_validacion.sql), con su resultado y tiempo
en [`docs/resultados/ex5_validacion.md`](resultados/ex5_validacion.md):

| Consulta | Fuente | Qué valida | Tiempo |
|---|---|---|---|
| Q5.1 | `parquet_file_metadata('data/raw/*/*/*.parquet')` | Archivos, registros y tamaño por tipo y año | 0.07 s |
| Q5.2 | metadatos + `generate_series` de meses esperados | Que no falte ningún mes ni haya archivos vacíos | 0.07 s |
| Q5.3 | metadatos vs. vista `viajes` (lee los 40 archivos) | Que el número de filas leídas sea igual al declarado | 0.22 s |
| Q5.4 | `parquet_schema('data/raw/*/*/*.parquet')` | Columnas y tipos que cambian entre archivos/años | 0.07 s |
| Q5.5 | vista `viajes_validos`, ene–ago, por `tipo` y `anio` | Que ambos años se consultan juntos y comparación de métricas | 9.7 s |
| Q5.6 | vista `viajes_validos`, ene–ago | Variación porcentual 2026 vs. 2024 | 7.7 s |
| Q5.7 | vista `viajes`, por `tipo` y `anio` | Calidad de datos por año (excluidos, sin metadatos) | 4.9 s |

Las vistas no se redefinen: el archivo usa `-- include: sql/ex4_analisis.sql`, que el runner
interpreta ejecutando antes la preparación (vistas) de ese archivo.

## 5.9 ¿Qué características del diseño permiten incorporar archivos sin rehacer el flujo?

1. **Año como parámetro, no como constante.** El script recibe los años (`ANIOS` o
   `--anio`); agregar un año es cambiar una línea o un argumento.
2. **Descarga idempotente.** Lo que ya existe localmente se omite sin consultar al servidor,
   y las descargas son atómicas (`.part` → renombrar). Volver a ejecutar el proceso completo es
   seguro y barato: solo trae lo nuevo.
3. **Estructura de directorios particionada `data/raw/<tipo>/<año>/`.** Cada archivo nuevo
   tiene un lugar predecible y el tipo y el año se pueden derivar de la ruta.
4. **Consultas sobre patrones (globs), no sobre archivos concretos.** `read_parquet('data/raw/yellow/*/*.parquet')`
   incluye cualquier año descargado. Las consultas no enumeran archivos ni años.
5. **Mes y año derivados del nombre del archivo** (`filename = true` + `regexp_extract`), lo
   que permite validar fechas y agrupar sin depender de valores sucios del contenido.
6. **Tolerancia a cambios de esquema** con `union_by_name = true`: columnas nuevas
   (`cbd_congestion_fee`, `request_source`) o ausentes no rompen la lectura.
7. **Normalización centralizada en vistas.** Nombres comunes, reglas de calidad y el
   tratamiento de columnas faltantes están en un solo lugar (`viajes` / `viajes_validos`). La
   corrección de la cuota CBD fue un cambio en una línea de la vista y se propagó a todas las
   consultas. El `-- include:` evita copiar esas definiciones entre archivos.
8. **Sin paso de carga.** Como se consulta el Parquet directamente, no hay tablas que
   actualizar ni cargas incrementales que mantener: los archivos nuevos se consultan apenas
   se descargan.
9. **Consultas versionadas y ejecutables por script** (`sql/*.sql` + `run_sql.py`). El mismo
   comando regenera todos los resultados, y las validaciones de completitud (Q5.1–Q5.4) sirven
   igual para cualquier año futuro.
