# Ejercicio 3 – Consultas directas sobre archivos Parquet

| Recurso | Ruta |
|---|---|
| Consultas SQL (fuente única) | [`sql/ex3_exploracion.sql`](../sql/ex3_exploracion.sql) |
| Resultados completos (SQL + salida + tiempo de cada consulta) | [`docs/resultados/ex3_exploracion.md`](resultados/ex3_exploracion.md) |
| Notebook | [`notebooks/ex3_exploracion.ipynb`](../notebooks/ex3_exploracion.ipynb) |
| Runner | [`scripts/run_sql.py`](../scripts/run_sql.py) |

Reproducir:

```bash
docker compose exec lab python scripts/run_sql.py sql/ex3_exploracion.sql
# o abrir notebooks/ex3_exploracion.ipynb en http://127.0.0.1:8888
```

## Cómo se consultan los archivos (3.7)

Ninguna consulta importa datos a una tabla. Se usa una conexión DuckDB **en
memoria** y las funciones que leen Parquet directamente:

- `read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true)`
  — lee todos los archivos que coinciden con el patrón como si fueran una sola tabla.
- `parquet_file_metadata(...)` y `parquet_schema(...)` — leen solo el *footer*
  de cada archivo (número de filas, tamaño, esquema) sin leer los datos.

Al inicio del SQL se crean dos **vistas** (`yellow`, `green`) que solo guardan
la expresión `read_parquet(...)`; no copian datos y cada consulta vuelve a leer
los archivos.

**Archivos fuente de todas las consultas:** los 16 archivos de 2026
(`data/raw/yellow/2026/yellow_tripdata_2026-01..08.parquet` y
`data/raw/green/2026/green_tripdata_2026-01..08.parquet`). Gracias al patrón
`*/*.parquet`, cuando se agreguen otros años las mismas consultas los
incluirán sin cambios.

Decisiones globales tomadas a partir de la exploración:

- **Usar siempre `union_by_name = true`**: los archivos no tienen todos el
  mismo esquema (Q3.4c). Sin esa opción DuckDB usa el esquema del primer archivo.
- **Consultar amarillos y verdes por separado** (o con alias al combinarlos):
  las columnas de fecha se llaman distinto (`tpep_*` vs `lpep_*`) y cada tipo
  tiene columnas propias.

---

## Documentación por consulta (3.8)

### Q3.1 – Cantidad de archivos (3.1)

- **Objetivo:** saber cuántos archivos hay por tipo y año, y cuánto pesan.
- **Fuente:** `parquet_file_metadata('data/raw/*/*/*.parquet')` (solo metadatos).
- **Resultado:**

  | tipo | año | archivos | MiB |
  |---|---|---|---|
  | green | 2026 | 8 | 7.9 |
  | yellow | 2026 | 8 | 487.8 |

- **Decisión:** coincide con los 16 archivos que reportó el script de descarga
  (enero–agosto). El tipo y el año se derivan de la ruta, por eso se mantiene la
  estructura `data/raw/<tipo>/<año>/`.

### Q3.2a / Q3.2b – Cantidad de registros (3.2)

- **Objetivo:** contar registros totales y por mes, y comprobar que los
  metadatos Parquet son confiables.
- **Fuente:** Q3.2a `parquet_file_metadata` (no lee filas); Q3.2b vistas
  `yellow` / `green` con la columna virtual `filename`.
- **Resultado:** **29 703 355** viajes amarillos y **337 114** verdes
  (30 040 469 en total). Ambos métodos dan el mismo número. Por mes, los
  amarillos van de 3.34 M (agosto) a 4.09 M (mayo); los verdes de 37 373
  (febrero) a 44 921 (mayo). Q3.2a tarda ~0.05 s y Q3.2b ~0.1 s.
- **Decisión:** para conteos totales se pueden usar los metadatos (no hace
  falta leer datos). Los amarillos son ~88 veces más que los verdes, así que las
  comparaciones entre tipos deben hacerse con proporciones/promedios, no con
  totales.

### Q3.3 – Columnas presentes (3.3)

- **Objetivo:** listar las columnas de cada tipo y en cuántos archivos aparece cada una.
- **Fuente:** `parquet_schema('data/raw/*/*/*.parquet')`.
- **Resultado:**
  - Amarillos: 21 columnas. Exclusivas: `tpep_pickup_datetime`,
    `tpep_dropoff_datetime`, `Airport_fee`.
  - Verdes: 22 columnas. Exclusivas: `lpep_pickup_datetime`,
    `lpep_dropoff_datetime`, `ehail_fee`, `trip_type`.
  - Comunes: `VendorID`, `passenger_count`, `trip_distance`, `RatecodeID`,
    `store_and_fwd_flag`, `PULocationID`, `DOLocationID`, `payment_type`,
    `fare_amount`, `extra`, `mta_tax`, `tip_amount`, `tolls_amount`,
    `improvement_surcharge`, `total_amount`, `congestion_surcharge`,
    `cbd_congestion_fee`, `request_source`.
  - `request_source` aparece solo en 3 de 8 archivos de cada tipo.
- **Decisión:** para unir ambos tipos se renombrarán las fechas a
  `pickup_datetime` / `dropoff_datetime` y se agregará una columna `tipo`.

### Q3.4a / Q3.4b / Q3.4c – Tipos de datos (3.4)

- **Objetivo:** conocer el tipo de cada columna y detectar cambios de esquema.
- **Fuente:** `DESCRIBE` sobre las vistas; `parquet_schema` por archivo.
- **Resultado:**

  | Tipo DuckDB | Columnas |
  |---|---|
  | `INTEGER` | `VendorID`, `PULocationID`, `DOLocationID` |
  | `BIGINT` | `passenger_count`, `RatecodeID`, `payment_type`, `trip_type` |
  | `TIMESTAMP` | fechas de abordaje y descenso (sin zona horaria) |
  | `DOUBLE` | `trip_distance` y todos los montos |
  | `VARCHAR` | `store_and_fwd_flag`, `request_source` |

  Q3.4c: los archivos de enero–mayo 2026 tienen 20 (amarillos) / 21 (verdes)
  columnas; desde **junio 2026** tienen una más, `request_source`.
- **Decisión:** los códigos categóricos (`VendorID`, `RatecodeID`,
  `payment_type`) son enteros y deben traducirse con el diccionario de la TLC
  para el análisis. `passenger_count` se guarda como `BIGINT` pero es un conteo
  pequeño. Las fechas no tienen zona horaria: se interpretan como hora local de
  Nueva York. Se usa `union_by_name = true` para tolerar el cambio de esquema
  (los meses sin `request_source` quedan con `NULL`).

### Q3.5a / Q3.5b – Muestra de registros (3.5)

- **Objetivo:** ver registros reales para entender el contenido de cada columna.
- **Fuente:** vistas `yellow` / `green` con
  `USING SAMPLE 5 ROWS (reservoir, 42)` (muestreo aleatorio con semilla fija para
  que la muestra sea reproducible).
- **Resultado:** ver las tablas en
  [`docs/resultados/ex3_exploracion.md`](resultados/ex3_exploracion.md#q35a-muestra-de-registros-amarillos).
  Ejemplo amarillo: viaje de 0.9 mi, 5.5 min, tarifa 7.90, total 16.10, pagado
  con tarjeta (`payment_type = 1`). La muestra verde incluye un viaje de 0.4 mi
  y 35 s con tarifa de 70.00 y `RatecodeID = 5` (tarifa negociada).
- **Decisión:** `total_amount` = suma de tarifa, recargos, impuestos, propina y
  peajes; se usará `total_amount` para ingresos y `fare_amount` para la tarifa
  base. Las tarifas negociadas (`RatecodeID = 5`) no siguen la relación
  distancia–tarifa y deben tratarse aparte al analizar precios.

### Q3.6 – Problemas de calidad de datos (3.6)

#### Q3.6a / Q3.6b / Q3.6i – Valores nulos

- **Objetivo:** cuantificar nulos e identificar si afectan a las mismas filas.
- **Resultado:**
  - Amarillos: **7 716 688 registros (26.0 %)** tienen `NULL` simultáneamente en
    `passenger_count`, `RatecodeID`, `store_and_fwd_flag`,
    `congestion_surcharge` y `Airport_fee`, y todos tienen `payment_type = 0`.
    Vienen de los vendors 1, 2 y 6 (Q3.6i).
  - Verdes: **48 775 registros (14.5 %)** con el mismo patrón (`payment_type`
    y `trip_type` también nulos); 34 847 de ellos son del vendor 6.
  - `ehail_fee` (verdes) es **100 % nulo**: columna sin información.
  - `request_source` es nulo en todos los archivos anteriores a junio.
- **Decisión:** no se eliminan esos registros (sí son viajes y tienen montos
  válidos, total promedio ~31 USD), pero se **excluyen** de los análisis de
  pasajeros, tipo de tarifa y forma de pago. `ehail_fee` se descarta.
  `request_source` solo se analizará desde junio 2026.

#### Q3.6c – Fechas fuera del mes del archivo

- **Objetivo:** comprobar que cada archivo mensual contiene solo viajes de ese mes.
- **Resultado:** 146 viajes amarillos y 98 verdes tienen fecha de abordaje
  fuera del mes del archivo; la fecha mínima es **2001-01-01** (amarillos) y
  **2008-12-31** (verdes).
- **Decisión:** en los análisis temporales se filtrará por la fecha de abordaje
  dentro del rango del archivo (o del año analizado), no por el nombre del archivo.

#### Q3.6d / Q3.6e – Tiempos, distancias, pasajeros y montos

| Problema | Amarillos | Verdes |
|---|---|---|
| Descenso antes del abordaje | 10 | 5 |
| Duración exactamente 0 | 371 673 (1.25 %) | 229 |
| Duración > 24 h | 263 | 4 |
| Distancia = 0 | 952 231 (3.2 %) | 12 212 (3.6 %) |
| Distancia > 100 mi | 1 223 | 72 |
| Distancia máxima | 328 522 mi | 179 831 mi |
| Pasajeros = 0 | 91 359 | 4 527 |
| Pasajeros > 6 | 28 | 99 |
| Tarifa negativa | 157 364 (0.53 %) | 999 |
| Total negativo | 161 835 (0.54 %) | 1 023 |
| Total > 1 000 USD | 49 | 1 |
| Propina negativa | 883 | 69 |

Percentiles (Q3.6e): la mediana de distancia es 1.86 mi (amarillos) y 2.07 mi
(verdes); el p99.9 es ~30 mi en ambos, pero el máximo supera las 179 000 mi. El
total mediano es 23.58 / 20.46 USD con p99.9 de 184 / 225 USD, y mínimos de
−2 560 / −501 USD.

- **Decisión:** los valores negativos corresponden a reversiones/reembolsos y
  las distancias o duraciones extremas a errores del taxímetro. Para el
  análisis se definirá un filtro de "viaje válido": duración entre 1 min y 6 h,
  distancia entre 0 y 100 mi (excluyendo 0), montos no negativos y
  `total_amount` < 1 000. Se reportará cuántos registros excluye. Como las
  distribuciones tienen colas muy largas, se usarán **medianas y percentiles**
  además de promedios.

#### Q3.6f – Códigos categóricos

- **Objetivo:** verificar que los códigos estén dentro del diccionario de datos de la TLC.
- **Resultado:**
  - `VendorID`: 1, 2, 6, 7 en amarillos y 1, 2, 6 en verdes — todos válidos
    según el diccionario vigente (6 y 7 son proveedores recientes).
  - `RatecodeID = 99` ("desconocido"): **769 693** amarillos (2.6 %) y 2 verdes.
  - `payment_type = 0`: 7 716 688 amarillos — son exactamente los registros con
    nulos de Q3.6a. Solo 2 registros con `payment_type = 5` (desconocido) y
    ninguno con 6 (anulado).
  - `trip_type` (verdes): 1 = street-hail (273 386), 2 = despacho (14 951).
- **Decisión:** `RatecodeID = 99` se tratará como desconocido igual que `NULL`.
  `payment_type = 0` se agrupa como "sin información de pago".

#### Q3.6g – Duplicados

- **Resultado:** 7 registros amarillos son duplicados exactos en todas las
  columnas; 0 en verdes.
- **Decisión:** el impacto es despreciable (7 de 29.7 M); se documenta pero no
  se corrige.

#### Q3.6h – Zonas

- **Resultado:** ningún `LocationID` está fuera del rango 1–265, pero 49 676
  abordajes y 178 136 descensos amarillos (y 1 131 / 5 600 verdes) usan las zonas
  264–265, que la TLC reserva para "desconocido / fuera de NYC".
- **Decisión:** estas zonas se excluyen de los análisis geográficos.

#### Otros hallazgos

- **Nombres inconsistentes:** `Airport_fee` empieza con mayúscula mientras que
  las demás columnas de montos están en minúscula; `VendorID`, `RatecodeID`,
  `PULocationID` mezclan estilos. DuckDB no distingue mayúsculas en los
  identificadores, pero conviene normalizar los nombres si se exportan los datos.
- **`request_source`** (desde junio 2026) toma valores como `HV0003` y `HV0005`
  (códigos de licencia de las plataformas de alto volumen, Uber y Lyft), `A`,
  `CC`, `EH0004` y `EH0010`. En los amarillos 2 903 446 viajes tienen un valor
  (2.3 M con `HV0003`). Parece indicar el canal por el que se solicitó el viaje;
  el diccionario de datos debe confirmarse antes de interpretarlo.

---

## 3.9 ¿Qué significa consultar directamente un archivo Parquet y por qué es útil?

Consultar directamente un Parquet significa que el motor SQL usa el archivo
como si fuera una tabla, **sin un paso previo de carga** (`INSERT`/`COPY`) a una
base de datos. En este laboratorio, `SELECT ... FROM read_parquet('data/raw/yellow/*/*.parquet')`
lee los 8 archivos en el momento de la consulta y devuelve el resultado; nada
queda copiado.

Es útil con volúmenes grandes porque Parquet está diseñado para eso y DuckDB
aprovecha su estructura:

- **Formato columnar.** Los datos de cada columna están juntos y comprimidos.
  Una consulta que usa 2 de 21 columnas solo lee esas 2 (*projection
  pushdown*). El `EXPLAIN ANALYZE` del notebook muestra un único
  `TABLE_SCAN` de tipo `READ_PARQUET` sobre los 8 archivos que filtra
  `trip_distance > 100` durante la lectura y tarda ~0.2 s para 29.7 M filas.
- **Metadatos en el footer.** Cada archivo guarda su número de filas, esquema y
  estadísticas (mín./máx.) por grupo de filas. Q3.1, Q3.2a y Q3.3 respondieron
  en ~0.05 s sin leer ninguna fila, y DuckDB puede saltarse grupos de filas
  cuyo mín./máx. no cumplen un filtro (*filter pushdown*).
- **Sin duplicar datos ni tiempo de carga.** Los ~500 MB de Parquet se
  consultan tal cual; no hace falta esperar una importación ni mantener una
  segunda copia sincronizada.
- **No necesita que todo quepa en memoria.** DuckDB procesa los archivos en
  bloques y en paralelo; 30 M de registros se exploraron sin cargarlos
  completos en RAM (a diferencia de `pandas.read_parquet`).
- **Incorporar datos es agregar archivos.** Con un patrón (`*/*.parquet`), un
  mes o año nuevo descargado en `data/raw/` aparece automáticamente en todas las
  consultas.

Limitaciones observadas: cada consulta vuelve a leer y descomprimir los
archivos (las consultas que recorren todas las columnas, como la de duplicados
Q3.6g, tardaron ~8 s), y las diferencias de esquema entre archivos deben
manejarse explícitamente (`union_by_name`). Esto se compara con una tabla
materializada en el Ejercicio 6.
