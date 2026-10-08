# Ejercicio 8 – Incorporación de 2025 y análisis completo

| Recurso | Ruta |
|---|---|
| Script de descarga | [`scripts/download_data.py`](../scripts/download_data.py) |
| Consultas del ejercicio | [`sql/ex8_tres_anios.sql`](../sql/ex8_tres_anios.sql) |
| Resultados | [`docs/resultados/ex8_tres_anios.md`](resultados/ex8_tres_anios.md) |
| Indicadores con los tres años | [`docs/resultados/ex8_indicadores.md`](resultados/ex8_indicadores.md) |
| Consultas del Ej. 3 con los tres años | [`docs/resultados/ex3_exploracion_2024_2025_2026.md`](resultados/ex3_exploracion_2024_2025_2026.md) |
| Consultas del Ej. 4 con los tres años | [`docs/resultados/ex4_analisis_2024_2025_2026.md`](resultados/ex4_analisis_2024_2025_2026.md) |

Reproducir:

```bash
docker compose exec lab python scripts/download_data.py
docker compose stop metabase
docker compose exec lab python scripts/run_sql.py sql/ex8_tres_anios.sql --memoria 2GB --hilos 2
docker compose exec lab python scripts/run_sql.py sql/ex3_exploracion.sql --salida ex3_exploracion_2024_2025_2026 --memoria 2GB --hilos 2
docker compose exec lab python scripts/run_sql.py sql/ex4_analisis.sql --salida ex4_analisis_2024_2025_2026 --memoria 2GB --hilos 2
docker compose exec lab python scripts/construir_db.py
docker compose exec lab python scripts/run_sql.py sql/ex7_indicadores.sql --db data/processed/taxis.duckdb --salida ex8_indicadores
docker compose start metabase
```

## 8.1 Cambio en el sistema de descarga

Solo hubo que agregar 2025 a la constante de años del script:

```diff
-ANIOS = (2024, 2026)
+ANIOS = (2024, 2025, 2026)
```

## 8.2 Los archivos existentes no se vuelven a descargar

Antes de ejecutar se guardó el listado con nombre, tamaño y fecha de modificación de los 40
archivos de 2024 y 2026. La primera ejecución reportó `descargados: 24, ya existian: 40`, es
decir, solo bajó los 12 meses de 2025 de cada tipo. Al comparar el listado de antes y después,
los 40 archivos tienen el mismo tamaño y la misma fecha; solo cambió la fecha de las carpetas
`yellow/` y `green/` porque se creó dentro la carpeta `2025/`. Una segunda ejecución reportó
`descargados: 0, ya existian: 64`, y `--verificar` terminó con 64 archivos OK (1.9 GiB) y 0
con problemas.

Q8.1 confirma desde DuckDB lo que hay en disco:

| Tipo | Año | Archivos | Registros |
|---|---|---|---|
| yellow | 2024 | 12 | 41 169 720 |
| yellow | 2025 | 12 | 48 722 602 |
| yellow | 2026 | 8 | 29 703 355 |
| green | 2024 | 12 | 660 218 |
| green | 2025 | 12 | 591 375 |
| green | 2026 | 8 | 337 114 |

## 8.3 ¿Las consultas siguen funcionando?

Se volvieron a ejecutar sin cambios las consultas de los ejercicios 3 y 4 sobre los 64
archivos (121 millones de registros).

La primera vez fallaron 3 de 32 consultas con `IO Error: Cannot allocate memory`: Q3.6g
(registros duplicados, un `DISTINCT` sobre todas las columnas), Q4.4 (siete medianas) y Q4.14
(cuartiles). No es un error del SQL, porque las mismas consultas funcionan con dos años: con
tres años estas operaciones necesitan guardar todos los valores en memoria y el contenedor
solo tiene 7.4 GB, que además comparte con Metabase. Probamos detener Metabase y limitar la
memoria de DuckDB a 4 GB, pero seguían fallando. Lo que funcionó fue limitar la memoria a 2 GB
y usar 2 hilos, para que DuckDB lea menos archivos a la vez y use disco cuando no le alcanza la
memoria. Para eso se agregaron las opciones `--memoria` y `--hilos` a `scripts/run_sql.py`. Con
ellas las 32 consultas terminan sin error.

| | Solo 2026 | 2024 y 2026 | 2024 a 2026 (2 GB, 2 hilos) |
|---|---|---|---|
| Registros | 30.0 M | 71.9 M | 121.2 M |
| Consultas con error | 0 | 0 | 0 |
| Tiempo total Ej. 3 | 16.8 s | 54.2 s | 5 min 5 s |
| Tiempo total Ej. 4 | 47.4 s | 119.4 s | 8 min 57 s |

El tiempo creció bastante más que los datos porque se usaron 2 hilos en lugar de 8. Ninguna
consulta tuvo que reescribirse: todas usan patrones `*/*.parquet` y la columna `cbd_congestion_fee`
ya se trataba con `coalesce` desde el Ejercicio 5.

## 8.4 Indicadores y tablero con los tres años

Se reconstruyó `data/processed/taxis.duckdb` con `scripts/construir_db.py` (Metabase tiene que
estar detenido porque tiene abierto el archivo) y se volvió a levantar Metabase. No se cambió
ninguna consulta ni el tablero: como los indicadores agrupan por mes o por año, el tablero
muestra 2025 automáticamente. Los valores están en `docs/resultados/ex8_indicadores.md`.

## 8.5 Evolución de los indicadores

Q8.2 compara enero a agosto de cada año para no mezclar estacionalidad:

| Tipo | Año | Viajes por día | Total promedio | Tarifa mediana | Velocidad mediana (mph) | % tarjeta | % sin info. de pago | % con cuota CBD |
|---|---|---|---|---|---|---|---|---|
| yellow | 2024 | 104 187 | 28.29 | 13.50 | 9.5 | 76.0 | 9.0 | 0 |
| yellow | 2025 | 117 700 | 28.29 | 14.20 | 9.7 | 68.8 | 19.7 | 73.1 |
| yellow | 2026 | 115 837 | 30.18 | 15.60 | 9.3 | 65.4 | 25.0 | 72.5 |
| green | 2024 | 1 691 | 23.77 | 13.50 | 10.4 | 67.9 | 4.1 | 0 |
| green | 2025 | 1 522 | 24.82 | 13.50 | 10.3 | 69.9 | 6.7 | 9.9 |
| green | 2026 | 1 315 | 25.38 | 13.50 | 10.0 | 65.6 | 14.9 | 8.6 |

Demanda (I1): los amarillos subieron 13 % de 2024 a 2025 y en 2026 se mantienen casi igual
(−1.6 %). El mes con más viajes diarios de todo el período es mayo de 2025 (131 575). Los verdes
bajan todos los años: −10 % en 2025 y −14 % en 2026. En los tres años los meses más bajos son
enero y los de verano (julio y agosto).

Precio (I4): la tarifa mediana de los amarillos sube cada año (13.50, 14.20 y 15.60 USD de enero
a agosto). El total promedio no cambió en 2025 aunque empezó la cuota CBD, y subió 6.7 % en 2026.

Pago (I5 e I10): el pago con tarjeta en amarillos baja de 76 % a 69 % y a 65 %, mientras los
viajes sin información de pago suben de 9 % a 20 % y a 25 %.

Propina (I6): se mantiene entre 19 % y 23 % de la tarifa en los tres años, sin una tendencia
clara.

Geografía (I7): Manhattan pasa de 88.5 % de los viajes en 2024 a 86.0 % en 2025 y 86.4 % en
2026, y Brooklyn de 1.6 % a 3.5 % y 3.7 %. El cambio ocurrió en 2025 y luego se mantuvo.

Velocidad (I8): entre las 7 y las 18 h la velocidad mediana de 2025 es igual o 0.1 a 0.2 mph
mayor que la de 2024, y la de 2026 es la más baja de los tres años en casi todas esas horas.

Aeropuertos (I9): su peso en los ingresos de los amarillos baja cada año: 27.8 %, 24.1 % y
20.9 %.

## 8.6 Cambios y patrones visibles al juntar los tres años

1. La cuota de congestión CBD aparece en enero de 2025 y desde ahí la paga cerca del 74 % de
   los viajes amarillos (Q8.3), con un promedio de 0.55 USD por viaje. Con solo 2024 y 2026 se
   veía un salto, pero no cuándo ocurrió. Ese año la velocidad mediana de los amarillos subió
   de 9.5 a 9.7 mph y en 2026 bajó a 9.3 mph, así que la mejora en el tráfico, si la hubo, no se
   mantuvo.
2. El crecimiento de los amarillos se dio en 2025 y en 2026 se estancó, mientras que los verdes
   bajan de forma constante (de 1 691 a 1 315 viajes diarios, −22 % en dos años). Comparando solo
   2024 y 2026 parecía un crecimiento continuo de los amarillos.
3. La calidad de los datos cambia de un año a otro y no de forma lineal. Los registros sin
   forma de pago aumentan cada año (9 %, 20 %, 25 %), pero los registros excluidos tienen su
   pico en 2025: entre 6 % y 13 % por mes, contra 3 % a 4.5 % en 2024 y 4.4 % a 5.9 % en 2026
   (I10). Q8.4 muestra que la causa son los montos negativos, que fueron 5.21 % de los
   registros de 2025 contra 1.54 % en 2024 y 0.46 % en 2026. Esto no se veía con 2024 y 2026.
4. Los viajes de aeropuerto pierden peso todos los años, tanto en viajes (10.1 %, 8.8 %, 8.1 %)
   como en ingresos (27.8 %, 24.1 %, 20.9 %).

## 8.7 Consultas utilizadas

| Consulta | Fuente | Objetivo |
|---|---|---|
| Q8.1 Archivos y registros por tipo y año | `parquet_file_metadata('data/raw/*/*/*.parquet')` | Confirmar que 2025 está completo |
| Q8.2 Resumen por año y tipo (enero a agosto) | vista `viajes_validos` | Comparar los tres años en el mismo período |
| Q8.3 Cuota de congestión CBD por mes | vista `viajes_validos`, amarillos desde 2025 | Ver cuándo empieza la cuota y cuántos la pagan |
| Q8.4 Registros excluidos por motivo y año | vista `viajes` | Explicar el aumento de registros excluidos en 2025 |
| I1 a I10 | `data/processed/taxis.duckdb` | Indicadores del tablero con los tres años |

El SQL completo y los resultados están en `sql/ex8_tres_anios.sql`,
`docs/resultados/ex8_tres_anios.md` y `docs/resultados/ex8_indicadores.md`.
