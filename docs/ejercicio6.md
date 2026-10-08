# Ejercicio 6 – Parquet versus tablas DuckDB

| Recurso | Ruta |
|---|---|
| Creación de la tabla | [`scripts/construir_db.py`](../scripts/construir_db.py) |
| Script del benchmark | [`scripts/benchmark.py`](../scripts/benchmark.py) |
| Consultas del benchmark | [`sql/ex6_benchmark.sql`](../sql/ex6_benchmark.sql) |
| Resultados | [`docs/resultados/ex6_benchmark.md`](resultados/ex6_benchmark.md) |

Reproducir:

```bash
docker compose stop metabase
docker compose exec lab python scripts/benchmark.py
```

## 6.1 y 6.2 Las dos estrategias

Parquet directo: las vistas `viajes`, `viajes_validos` y `zonas` del Ejercicio 4, que leen los
archivos de `data/raw/` cada vez que se consultan.

Tabla materializada: `scripts/construir_db.py` ejecuta esas mismas vistas y guarda el resultado
en `data/processed/taxis.duckdb` como tablas (`CREATE TABLE viajes AS SELECT * FROM viajes`,
igual con `zonas`). Dentro de la base se crea la vista `viajes_validos` con la misma definición
del Ejercicio 4, ahora sobre la tabla. Así las consultas se escriben igual para las dos
estrategias y devuelven el mismo resultado.

## 6.3 y 6.8 Consultas del benchmark

Se tomaron cinco consultas del Ejercicio 4 que representan los tipos de operación del análisis:

| Consulta | Tipo de operación | Origen |
|---|---|---|
| B1 Conteo de viajes válidos por tipo | recorrido completo con agregación simple | Q3.2 / Q4.13 |
| B2 Volumen mensual e ingresos por tipo | agrupación por mes y tipo | Q4.1 |
| B3 Medianas del viaje típico | agregaciones holísticas (median) | Q4.4 |
| B4 Borough de origen | join con la tabla de zonas | Q4.6 |
| B5 Primera semana de enero de 2026 | filtro selectivo por fecha | Q4.3 |

## 6.4 a 6.7 Ejecución y resultados

Para cada cantidad de datos el script crea la base, ejecuta cada consulta 3 veces sobre Parquet y
3 veces sobre la tabla, y guarda la mediana del tiempo. Se probaron cuatro tamaños, que se eligen
con un patrón sobre `data/raw/<tipo>/`.

Datos y costo de materializar:

| Datos | Registros | Parquet (MiB) | Tabla DuckDB (MiB) | Creación de la tabla (s) |
|---|---|---|---|---|
| 1 mes (2026-01) | 3 765 161 | 62 | 131 | 5.9 |
| 1 año (2026) | 30 040 469 | 496 | 1 039 | 32.3 |
| 2 años (2024 y 2026) | 71 870 407 | 1 172 | 2 474 | 77.3 |
| 3 años (2024 a 2026) | 121 184 384 | 1 977 | 4 210 | 135.4 |

Tiempos (segundos, mediana de 3 ejecuciones):

| Consulta | 1 mes Parquet | 1 mes Tabla | 1 año Parquet | 1 año Tabla | 2 años Parquet | 2 años Tabla | 3 años Parquet | 3 años Tabla |
|---|---|---|---|---|---|---|---|---|
| B1 Conteo | 0.94 | 0.02 | 5.18 | 0.18 | 9.85 | 0.28 | 22.20 | 0.72 |
| B2 Volumen mensual | 0.82 | 0.06 | 4.70 | 0.39 | 9.38 | 0.74 | 15.65 | 1.73 |
| B3 Medianas | 1.27 | 0.63 | 10.33 | 5.30 | 22.60 | 13.20 | 40.78 | 26.32 |
| B4 Join con zonas | 0.97 | 0.07 | 6.19 | 0.41 | 11.21 | 0.82 | 18.30 | 1.40 |
| B5 Filtro por fecha | 0.37 | 0.01 | 0.73 | 0.03 | 1.10 | 0.02 | 1.25 | 0.02 |

Cuántas veces más rápida fue la tabla:

| Consulta | 1 mes | 1 año | 2 años | 3 años |
|---|---|---|---|---|
| B1 | 44x | 29x | 35x | 31x |
| B2 | 13x | 12x | 13x | 9x |
| B3 | 2.0x | 2.0x | 1.7x | 1.5x |
| B4 | 14x | 15x | 14x | 13x |
| B5 | 32x | 29x | 57x | 62x |

## 6.9 Análisis

La tabla fue más rápida en todas las consultas y en todos los tamaños. La diferencia es grande en
las consultas que solo recorren y agrupan (B1, B2 y B4, entre 9 y 44 veces) porque con Parquet
cada consulta tiene que leer y descomprimir los archivos y además recalcular la vista: la
duración, la fecha del archivo y las 8 reglas de calidad. En la tabla eso ya está calculado y
guardado en el formato propio de DuckDB.

En B3 la diferencia es de apenas 1.5 a 2 veces. Calcular medianas exige guardar y ordenar todos
los valores, y ese costo es el mismo sin importar de dónde vienen los datos, así que la lectura
deja de ser lo que más pesa.

B5 es donde más gana la tabla (hasta 62 veces) y además su tiempo casi no crece con el volumen
(0.01 a 0.02 s). DuckDB guarda el mínimo y el máximo de cada bloque de la tabla y se salta los
que no tienen fechas de esa semana. Con Parquet también se saltan grupos de filas usando las
estadísticas de cada archivo (por eso B5 tarda 1.25 s y no 22 s como B1), pero hay que abrir los
64 archivos y leer sus metadatos en cada consulta.

Al aumentar los datos, los tiempos de las dos estrategias crecen de forma casi proporcional al
número de registros: de 1 a 3 años hay 4 veces más registros y B1 tarda 4.3 veces más con
Parquet y 4 veces más con la tabla. Con 1 mes la diferencia absoluta es menor a un segundo, así
que ahí no importa mucho la estrategia; con 3 años la diferencia es de 15 a 20 segundos por
consulta.

La tabla tiene costos: ocupa unas 2.1 veces el espacio de los Parquet (4.2 GB contra 2 GB) y
crearla tardó 135 s con 3 años, más o menos lo mismo que ejecutar 6 o 7 consultas sobre Parquet.
También hay que reconstruirla cuando llegan archivos nuevos. Hay que tomar en cuenta que los
archivos están en una carpeta de Windows montada en Docker, lo que hace más lenta la lectura de
Parquet que en un disco local.

## 6.10 ¿Cuándo usar cada estrategia?

Conviene consultar Parquet directamente cuando los datos cambian seguido o recién llegan, cuando
se hacen pocas consultas o consultas de exploración, cuando se quieren validar archivos (los
metadatos se leen sin cargar los datos) o cuando el espacio en disco es limitado.

Conviene materializar una tabla cuando las mismas consultas se ejecutan muchas veces, como en un
tablero, cuando hay transformaciones costosas que se repiten en cada consulta, cuando hay filtros
selectivos por fecha u otra columna ordenada, y cuando el tiempo de respuesta importa más que el
espacio. Por eso en este laboratorio el análisis exploratorio se hizo sobre Parquet y el tablero
de Metabase (Ejercicio 7) usa la tabla.
