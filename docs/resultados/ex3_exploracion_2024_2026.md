# Resultados de `sql/ex3_exploracion.sql`

Generado con `python scripts/run_sql.py sql/ex3_exploracion.sql` el 2026-10-08 18:59 (DuckDB 1.5.5).

## Q3.1 Cantidad de archivos disponibles por tipo y anio

```sql
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    split_part(replace(file_name, '\', '/'), '/', 4) AS anio,
    count(*)                                         AS archivos,
    round(sum(file_size_bytes) / 1024 / 1024, 1)     AS mib
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo, anio;
```

Tiempo: 0.06 s

| tipo | anio | archivos | mib |
|---|---|---|---|
| green | 2024 | 12 | 15.2 |
| green | 2026 | 8 | 7.9 |
| yellow | 2024 | 12 | 660.9 |
| yellow | 2026 | 8 | 487.8 |

## Q3.2a Cantidad de registros segun los metadatos Parquet (sin leer filas)

```sql
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    sum(num_rows)                                    AS registros
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo;
```

Tiempo: 0.06 s

| tipo | registros |
|---|---|
| green | 997332 |
| yellow | 70873075 |

## Q3.2b Cantidad de registros por archivo (conteo leyendo los datos)

```sql
SELECT 'yellow' AS tipo, regexp_extract(filename, '(\d{4}-\d{2})', 1) AS mes, count(*) AS registros
FROM yellow GROUP BY ALL
UNION ALL
SELECT 'green', regexp_extract(filename, '(\d{4}-\d{2})', 1), count(*)
FROM green GROUP BY ALL
ORDER BY tipo DESC, mes;
```

Tiempo: 0.14 s

| tipo | mes | registros |
|---|---|---|
| yellow | 2024-01 | 2964624 |
| yellow | 2024-02 | 3007526 |
| yellow | 2024-03 | 3582628 |
| yellow | 2024-04 | 3514289 |
| yellow | 2024-05 | 3723833 |
| yellow | 2024-06 | 3539193 |
| yellow | 2024-07 | 3076903 |
| yellow | 2024-08 | 2979183 |
| yellow | 2024-09 | 3633030 |
| yellow | 2024-10 | 3833771 |
| yellow | 2024-11 | 3646369 |
| yellow | 2024-12 | 3668371 |
| yellow | 2026-01 | 3724889 |
| yellow | 2026-02 | 3399866 |
| yellow | 2026-03 | 3952451 |
| yellow | 2026-04 | 3831240 |
| yellow | 2026-05 | 4090836 |
| yellow | 2026-06 | 3837248 |
| yellow | 2026-07 | 3530109 |
| yellow | 2026-08 | 3336716 |
| green | 2024-01 | 56551 |
| green | 2024-02 | 53577 |
| green | 2024-03 | 57457 |
| green | 2024-04 | 56471 |
| green | 2024-05 | 61003 |
| green | 2024-06 | 54748 |
| green | 2024-07 | 51837 |
| green | 2024-08 | 51771 |
| green | 2024-09 | 54440 |
| green | 2024-10 | 56147 |
| green | 2024-11 | 52222 |
| green | 2024-12 | 53994 |
| green | 2026-01 | 40272 |
| green | 2026-02 | 37373 |
| green | 2026-03 | 44208 |
| green | 2026-04 | 44238 |
| green | 2026-05 | 44921 |
| green | 2026-06 | 44163 |
| green | 2026-07 | 41252 |
| green | 2026-08 | 40687 |

## Q3.3 Columnas presentes y en cuantos archivos aparece cada una

```sql
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    name                                             AS columna,
    count(*)                                         AS archivos_con_columna
FROM parquet_schema('data/raw/*/*/*.parquet')
WHERE name <> 'schema'
GROUP BY ALL
ORDER BY tipo DESC, archivos_con_columna, columna;
```

Tiempo: 0.06 s

| tipo | columna | archivos_con_columna |
|---|---|---|
| yellow | request_source | 3 |
| yellow | cbd_congestion_fee | 8 |
| yellow | Airport_fee | 20 |
| yellow | DOLocationID | 20 |
| yellow | PULocationID | 20 |
| yellow | RatecodeID | 20 |
| yellow | VendorID | 20 |
| yellow | congestion_surcharge | 20 |
| yellow | extra | 20 |
| yellow | fare_amount | 20 |
| yellow | improvement_surcharge | 20 |
| yellow | mta_tax | 20 |
| yellow | passenger_count | 20 |
| yellow | payment_type | 20 |
| yellow | store_and_fwd_flag | 20 |
| yellow | tip_amount | 20 |
| yellow | tolls_amount | 20 |
| yellow | total_amount | 20 |
| yellow | tpep_dropoff_datetime | 20 |
| yellow | tpep_pickup_datetime | 20 |
| yellow | trip_distance | 20 |
| green | request_source | 3 |
| green | cbd_congestion_fee | 8 |
| green | DOLocationID | 20 |
| green | PULocationID | 20 |
| green | RatecodeID | 20 |
| green | VendorID | 20 |
| green | congestion_surcharge | 20 |
| green | ehail_fee | 20 |
| green | extra | 20 |
| green | fare_amount | 20 |
| green | improvement_surcharge | 20 |
| green | lpep_dropoff_datetime | 20 |
| green | lpep_pickup_datetime | 20 |
| green | mta_tax | 20 |
| green | passenger_count | 20 |
| green | payment_type | 20 |
| green | store_and_fwd_flag | 20 |
| green | tip_amount | 20 |
| green | tolls_amount | 20 |
| green | total_amount | 20 |
| green | trip_distance | 20 |
| green | trip_type | 20 |

## Q3.4a Tipos de datos de las columnas (taxis amarillos)

```sql
DESCRIBE SELECT * EXCLUDE (filename) FROM yellow;
```

Tiempo: 0.03 s

| column_name | column_type | null | key | default | extra |
|---|---|---|---|---|---|
| VendorID | INTEGER | YES | NULL | NULL | NULL |
| tpep_pickup_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| tpep_dropoff_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| passenger_count | BIGINT | YES | NULL | NULL | NULL |
| trip_distance | DOUBLE | YES | NULL | NULL | NULL |
| RatecodeID | BIGINT | YES | NULL | NULL | NULL |
| store_and_fwd_flag | VARCHAR | YES | NULL | NULL | NULL |
| PULocationID | INTEGER | YES | NULL | NULL | NULL |
| DOLocationID | INTEGER | YES | NULL | NULL | NULL |
| payment_type | BIGINT | YES | NULL | NULL | NULL |
| fare_amount | DOUBLE | YES | NULL | NULL | NULL |
| extra | DOUBLE | YES | NULL | NULL | NULL |
| mta_tax | DOUBLE | YES | NULL | NULL | NULL |
| tip_amount | DOUBLE | YES | NULL | NULL | NULL |
| tolls_amount | DOUBLE | YES | NULL | NULL | NULL |
| improvement_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| total_amount | DOUBLE | YES | NULL | NULL | NULL |
| congestion_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| Airport_fee | DOUBLE | YES | NULL | NULL | NULL |
| cbd_congestion_fee | DOUBLE | YES | NULL | NULL | NULL |
| request_source | VARCHAR | YES | NULL | NULL | NULL |

## Q3.4b Tipos de datos de las columnas (taxis verdes)

```sql
DESCRIBE SELECT * EXCLUDE (filename) FROM green;
```

Tiempo: 0.03 s

| column_name | column_type | null | key | default | extra |
|---|---|---|---|---|---|
| VendorID | INTEGER | YES | NULL | NULL | NULL |
| lpep_pickup_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| lpep_dropoff_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| store_and_fwd_flag | VARCHAR | YES | NULL | NULL | NULL |
| RatecodeID | BIGINT | YES | NULL | NULL | NULL |
| PULocationID | INTEGER | YES | NULL | NULL | NULL |
| DOLocationID | INTEGER | YES | NULL | NULL | NULL |
| passenger_count | BIGINT | YES | NULL | NULL | NULL |
| trip_distance | DOUBLE | YES | NULL | NULL | NULL |
| fare_amount | DOUBLE | YES | NULL | NULL | NULL |
| extra | DOUBLE | YES | NULL | NULL | NULL |
| mta_tax | DOUBLE | YES | NULL | NULL | NULL |
| tip_amount | DOUBLE | YES | NULL | NULL | NULL |
| tolls_amount | DOUBLE | YES | NULL | NULL | NULL |
| ehail_fee | DOUBLE | YES | NULL | NULL | NULL |
| improvement_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| total_amount | DOUBLE | YES | NULL | NULL | NULL |
| payment_type | BIGINT | YES | NULL | NULL | NULL |
| trip_type | BIGINT | YES | NULL | NULL | NULL |
| congestion_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| cbd_congestion_fee | DOUBLE | YES | NULL | NULL | NULL |
| request_source | VARCHAR | YES | NULL | NULL | NULL |

## Q3.4c Archivos que contienen la columna request_source

```sql
SELECT
    regexp_extract(file_name, '([a-z]+_tripdata_\d{4}-\d{2})', 1) AS archivo,
    count(*) FILTER (WHERE name = 'request_source')               AS tiene_request_source,
    count(*) - 1                                                  AS columnas
FROM parquet_schema('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY archivo;
```

Tiempo: 0.06 s

| archivo | tiene_request_source | columnas |
|---|---|---|
| green_tripdata_2024-01 | 0 | 20 |
| green_tripdata_2024-02 | 0 | 20 |
| green_tripdata_2024-03 | 0 | 20 |
| green_tripdata_2024-04 | 0 | 20 |
| green_tripdata_2024-05 | 0 | 20 |
| green_tripdata_2024-06 | 0 | 20 |
| green_tripdata_2024-07 | 0 | 20 |
| green_tripdata_2024-08 | 0 | 20 |
| green_tripdata_2024-09 | 0 | 20 |
| green_tripdata_2024-10 | 0 | 20 |
| green_tripdata_2024-11 | 0 | 20 |
| green_tripdata_2024-12 | 0 | 20 |
| green_tripdata_2026-01 | 0 | 21 |
| green_tripdata_2026-02 | 0 | 21 |
| green_tripdata_2026-03 | 0 | 21 |
| green_tripdata_2026-04 | 0 | 21 |
| green_tripdata_2026-05 | 0 | 21 |
| green_tripdata_2026-06 | 1 | 22 |
| green_tripdata_2026-07 | 1 | 22 |
| green_tripdata_2026-08 | 1 | 22 |
| yellow_tripdata_2024-01 | 0 | 19 |
| yellow_tripdata_2024-02 | 0 | 19 |
| yellow_tripdata_2024-03 | 0 | 19 |
| yellow_tripdata_2024-04 | 0 | 19 |
| yellow_tripdata_2024-05 | 0 | 19 |
| yellow_tripdata_2024-06 | 0 | 19 |
| yellow_tripdata_2024-07 | 0 | 19 |
| yellow_tripdata_2024-08 | 0 | 19 |
| yellow_tripdata_2024-09 | 0 | 19 |
| yellow_tripdata_2024-10 | 0 | 19 |
| yellow_tripdata_2024-11 | 0 | 19 |
| yellow_tripdata_2024-12 | 0 | 19 |
| yellow_tripdata_2026-01 | 0 | 20 |
| yellow_tripdata_2026-02 | 0 | 20 |
| yellow_tripdata_2026-03 | 0 | 20 |
| yellow_tripdata_2026-04 | 0 | 20 |
| yellow_tripdata_2026-05 | 0 | 20 |
| yellow_tripdata_2026-06 | 1 | 21 |
| yellow_tripdata_2026-07 | 1 | 21 |
| yellow_tripdata_2026-08 | 1 | 21 |

## Q3.5a Muestra de registros (amarillos)

```sql
SELECT * EXCLUDE (filename)
FROM yellow
USING SAMPLE 5 ROWS (reservoir, 42);
```

Tiempo: 0.33 s

| VendorID | tpep_pickup_datetime | tpep_dropoff_datetime | passenger_count | trip_distance | RatecodeID | store_and_fwd_flag | PULocationID | DOLocationID | payment_type | fare_amount | extra | mta_tax | tip_amount | tolls_amount | improvement_surcharge | total_amount | congestion_surcharge | Airport_fee | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2024-01-01 00:29:59 | 2024-01-01 00:36:40 | 1 | 1.3 | 1 | N | 239 | 236 | 1 | 9.3 | 3.5 | 0.5 | 1 | 0 | 1 | 15.3 | 2.5 | 0 | NULL | NULL |
| 2 | 2024-01-01 00:20:38 | 2024-01-01 00:32:34 | 1 | 1.89 | 1 | N | 170 | 113 | 4 | -12.8 | -1 | -0.5 | 0 | 0 | -1 | -17.8 | -2.5 | 0 | NULL | NULL |
| 1 | 2024-01-01 02:25:40 | 2024-01-01 02:27:31 | 1 | 0.5 | 1 | N | 141 | 229 | 1 | 4.4 | 3.5 | 0.5 | 1.85 | 0 | 1 | 11.25 | 2.5 | 0 | NULL | NULL |
| 2 | 2024-01-01 03:45:11 | 2024-01-01 04:05:43 | 2 | 12.69 | 1 | N | 163 | 200 | 1 | 49.9 | 1 | 0.5 | 11.62 | 3.18 | 1 | 69.7 | 2.5 | 0 | NULL | NULL |
| 2 | 2024-01-01 03:39:03 | 2024-01-01 03:52:34 | 5 | 3.82 | 1 | N | 261 | 246 | 1 | 19.1 | 1 | 0.5 | 4.82 | 0 | 1 | 28.92 | 2.5 | 0 | NULL | NULL |

## Q3.5b Muestra de registros (verdes)

```sql
SELECT * EXCLUDE (filename)
FROM green
USING SAMPLE 5 ROWS (reservoir, 42);
```

Tiempo: 0.13 s

| VendorID | lpep_pickup_datetime | lpep_dropoff_datetime | store_and_fwd_flag | RatecodeID | PULocationID | DOLocationID | passenger_count | trip_distance | fare_amount | extra | mta_tax | tip_amount | tolls_amount | ehail_fee | improvement_surcharge | total_amount | payment_type | trip_type | congestion_surcharge | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2024-01-01 17:06:29 | 2024-01-01 17:46:39 | N | 1 | 129 | 197 | 1 | 10.06 | 53.4 | 0 | 0.5 | 1 | 0 | NULL | 1 | 55.9 | 1 | 1 | 0 | NULL | NULL |
| 2 | 2024-01-02 12:50:13 | 2024-01-02 12:57:40 | N | 1 | 236 | 237 | 1 | 1.22 | 9.3 | 0 | 0.5 | 0 | 0 | NULL | 1 | 13.55 | 2 | 1 | 2.75 | NULL | NULL |
| 2 | 2024-01-10 11:08:40 | 2024-01-10 11:16:24 | N | 1 | 75 | 236 | 1 | 1.08 | 8.6 | 0 | 0.5 | 0 | 0 | NULL | 1 | 12.85 | 2 | 1 | 2.75 | NULL | NULL |
| 2 | 2024-01-11 17:28:44 | 2024-01-11 17:43:00 | N | 1 | 75 | 141 | 1 | 2 | 14.9 | 2.5 | 0.5 | 5.41 | 0 | NULL | 1 | 27.06 | 1 | 1 | 2.75 | NULL | NULL |
| 2 | 2024-01-12 17:01:58 | 2024-01-12 17:15:18 | N | 1 | 95 | 28 | 1 | 1.56 | 14.2 | 2.5 | 0.5 | 3.64 | 0 | NULL | 1 | 21.84 | 1 | 1 | 0 | NULL | NULL |

## Q3.6a Valores nulos por columna (amarillos)

```sql
SELECT
    count(*)                                    AS registros,
    count(*) - count(passenger_count)           AS null_passenger_count,
    count(*) - count(RatecodeID)                AS null_ratecodeid,
    count(*) - count(store_and_fwd_flag)        AS null_store_and_fwd_flag,
    count(*) - count(congestion_surcharge)      AS null_congestion_surcharge,
    count(*) - count(Airport_fee)               AS null_airport_fee,
    count(*) - count(request_source)            AS null_request_source,
    round(100.0 * (count(*) - count(passenger_count)) / count(*), 2) AS pct_null_passenger_count
FROM yellow;
```

Tiempo: 0.62 s

| registros | null_passenger_count | null_ratecodeid | null_store_and_fwd_flag | null_congestion_surcharge | null_airport_fee | null_request_source | pct_null_passenger_count |
|---|---|---|---|---|---|---|---|
| 70873075 | 11807920 | 11807920 | 11807920 | 11807920 | 11807920 | 67969629 | 16.66 |

## Q3.6b Valores nulos por columna (verdes)

```sql
SELECT
    count(*)                                    AS registros,
    count(*) - count(passenger_count)           AS null_passenger_count,
    count(*) - count(RatecodeID)                AS null_ratecodeid,
    count(*) - count(payment_type)              AS null_payment_type,
    count(*) - count(trip_type)                 AS null_trip_type,
    count(*) - count(congestion_surcharge)      AS null_congestion_surcharge,
    count(*) - count(ehail_fee)                 AS null_ehail_fee,
    count(*) - count(request_source)            AS null_request_source
FROM green;
```

Tiempo: 0.08 s

| registros | null_passenger_count | null_ratecodeid | null_payment_type | null_trip_type | null_congestion_surcharge | null_ehail_fee | null_request_source |
|---|---|---|---|---|---|---|---|
| 997332 | 73103 | 73103 | 73103 | 73187 | 73103 | 997332 | 978121 |

## Q3.6c Registros con fecha de abordaje fuera del mes del archivo

```sql
SELECT 'yellow' AS tipo,
       count(*) FILTER (WHERE strftime(tpep_pickup_datetime, '%Y-%m')
                              <> regexp_extract(filename, '(\d{4}-\d{2})', 1)) AS fuera_de_mes,
       min(tpep_pickup_datetime) AS pickup_min,
       max(tpep_pickup_datetime) AS pickup_max
FROM yellow
UNION ALL
SELECT 'green',
       count(*) FILTER (WHERE strftime(lpep_pickup_datetime, '%Y-%m')
                              <> regexp_extract(filename, '(\d{4}-\d{2})', 1)),
       min(lpep_pickup_datetime),
       max(lpep_pickup_datetime)
FROM green;
```

Tiempo: 1.66 s

| tipo | fuera_de_mes | pickup_min | pickup_max |
|---|---|---|---|
| yellow | 566 | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 |
| green | 262 | 2008-12-31 00:00:00 | 2026-08-31 23:58:28 |

## Q3.6d Inconsistencias de tiempo, distancia, pasajeros y montos

```sql
WITH viajes AS (
    SELECT 'yellow' AS tipo, tpep_pickup_datetime AS pickup, tpep_dropoff_datetime AS dropoff,
           passenger_count, trip_distance, fare_amount, total_amount, tip_amount
    FROM yellow
    UNION ALL
    SELECT 'green', lpep_pickup_datetime, lpep_dropoff_datetime,
           passenger_count, trip_distance, fare_amount, total_amount, tip_amount
    FROM green
)
SELECT
    tipo,
    count(*)                                                           AS registros,
    count(*) FILTER (WHERE dropoff < pickup)                           AS dropoff_antes_pickup,
    count(*) FILTER (WHERE dropoff = pickup)                           AS duracion_cero,
    count(*) FILTER (WHERE dropoff - pickup > INTERVAL 24 HOUR)        AS duracion_mayor_24h,
    count(*) FILTER (WHERE trip_distance = 0)                          AS distancia_cero,
    count(*) FILTER (WHERE trip_distance < 0)                          AS distancia_negativa,
    count(*) FILTER (WHERE trip_distance > 100)                        AS distancia_mayor_100mi,
    count(*) FILTER (WHERE passenger_count = 0)                        AS pasajeros_cero,
    count(*) FILTER (WHERE passenger_count > 6)                        AS pasajeros_mas_6,
    count(*) FILTER (WHERE fare_amount < 0)                            AS tarifa_negativa,
    count(*) FILTER (WHERE total_amount < 0)                           AS total_negativo,
    count(*) FILTER (WHERE total_amount > 1000)                        AS total_mayor_1000,
    count(*) FILTER (WHERE tip_amount < 0)                             AS propina_negativa
FROM viajes
GROUP BY tipo
ORDER BY tipo DESC;
```

Tiempo: 3.80 s

| tipo | registros | dropoff_antes_pickup | duracion_cero | duracion_mayor_24h | distancia_cero | distancia_negativa | distancia_mayor_100mi | pasajeros_cero | pasajeros_mas_6 | tarifa_negativa | total_negativo | total_mayor_1000 | propina_negativa |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 70873075 | 1585 | 383608 | 493 | 1728536 | 0 | 2836 | 492713 | 312 | 888388 | 771179 | 92 | 2214 |
| green | 997332 | 7 | 889 | 4 | 46786 | 0 | 307 | 11320 | 247 | 3143 | 3197 | 2 | 128 |

## Q3.6e Distribucion de valores extremos de distancia y monto total

```sql
SELECT 'yellow' AS tipo,
       min(trip_distance) AS dist_min,
       quantile_cont(trip_distance, [0.5, 0.99, 0.999]) AS dist_p50_p99_p999,
       max(trip_distance) AS dist_max,
       min(total_amount)  AS total_min,
       quantile_cont(total_amount, [0.5, 0.99, 0.999])  AS total_p50_p99_p999,
       max(total_amount)  AS total_max
FROM yellow
UNION ALL
SELECT 'green', min(trip_distance), quantile_cont(trip_distance, [0.5, 0.99, 0.999]), max(trip_distance),
       min(total_amount), quantile_cont(total_amount, [0.5, 0.99, 0.999]), max(total_amount)
FROM green;
```

Tiempo: 6.48 s

| tipo | dist_min | dist_p50_p99_p999 | dist_max | total_min | total_p50_p99_p999 | total_max |
|---|---|---|---|---|---|---|
| yellow | 0 | [1.8, 19.85, 30.3] | 398,608.62 | -2,560.2 | [22, 105.06, 183.07] | 335,550.94 |
| green | 0 | [1.93, 17.03, 29.9667] | 233,972.43 | -501.5 | [19.68, 96.2, 200.7334] | 1,678.2 |

## Q3.6f Codigos categoricos fuera del diccionario de la TLC

```sql
-- Diccionario: VendorID {1,2,6,7}; RatecodeID {1..6, 99}; payment_type {0..6};
-- store_and_fwd_flag {Y,N}; trip_type (verdes) {1,2}.
SELECT 'yellow' AS tipo, 'VendorID' AS columna, VendorID::VARCHAR AS valor, count(*) AS registros FROM yellow GROUP BY ALL
UNION ALL SELECT 'yellow', 'RatecodeID', RatecodeID::VARCHAR, count(*) FROM yellow GROUP BY ALL
UNION ALL SELECT 'yellow', 'payment_type', payment_type::VARCHAR, count(*) FROM yellow GROUP BY ALL
UNION ALL SELECT 'green', 'VendorID', VendorID::VARCHAR, count(*) FROM green GROUP BY ALL
UNION ALL SELECT 'green', 'RatecodeID', RatecodeID::VARCHAR, count(*) FROM green GROUP BY ALL
UNION ALL SELECT 'green', 'payment_type', payment_type::VARCHAR, count(*) FROM green GROUP BY ALL
UNION ALL SELECT 'green', 'trip_type', trip_type::VARCHAR, count(*) FROM green GROUP BY ALL
ORDER BY tipo DESC, columna, valor NULLS FIRST;
```

Tiempo: 1.64 s

| tipo | columna | valor | registros |
|---|---|---|---|
| yellow | RatecodeID | NULL | 11807920 |
| yellow | RatecodeID | 1 | 54753099 |
| yellow | RatecodeID | 2 | 2101806 |
| yellow | RatecodeID | 3 | 220003 |
| yellow | RatecodeID | 4 | 168927 |
| yellow | RatecodeID | 5 | 584562 |
| yellow | RatecodeID | 6 | 91 |
| yellow | RatecodeID | 99 | 1236667 |
| yellow | VendorID | 1 | 15182989 |
| yellow | VendorID | 2 | 55261277 |
| yellow | VendorID | 6 | 61459 |
| yellow | VendorID | 7 | 367350 |
| yellow | payment_type | 0 | 11807920 |
| yellow | payment_type | 1 | 49393167 |
| yellow | payment_type | 2 | 8248119 |
| yellow | payment_type | 3 | 389881 |
| yellow | payment_type | 4 | 1033982 |
| yellow | payment_type | 5 | 6 |
| green | RatecodeID | NULL | 73103 |
| green | RatecodeID | 1 | 871065 |
| green | RatecodeID | 2 | 2728 |
| green | RatecodeID | 3 | 620 |
| green | RatecodeID | 4 | 1085 |
| green | RatecodeID | 5 | 48641 |
| green | RatecodeID | 6 | 6 |
| green | RatecodeID | 99 | 84 |
| green | VendorID | 1 | 109146 |
| green | VendorID | 2 | 853339 |
| green | VendorID | 6 | 34847 |
| green | payment_type | NULL | 73103 |
| green | payment_type | 1 | 674667 |
| green | payment_type | 2 | 240934 |
| green | payment_type | 3 | 6288 |
| green | payment_type | 4 | 2311 |
| green | payment_type | 5 | 29 |
| green | trip_type | NULL | 73187 |
| green | trip_type | 1 | 880205 |
| green | trip_type | 2 | 43940 |

## Q3.6g Registros completamente duplicados

```sql
SELECT 'yellow' AS tipo, count(*) - (SELECT count(*) FROM (SELECT DISTINCT * EXCLUDE (filename) FROM yellow)) AS duplicados
FROM yellow
UNION ALL
SELECT 'green', count(*) - (SELECT count(*) FROM (SELECT DISTINCT * EXCLUDE (filename) FROM green))
FROM green;
```

Tiempo: 37.23 s

| tipo | duplicados |
|---|---|
| yellow | 11 |
| green | 0 |

## Q3.6h Identificadores de zona fuera de las zonas validas (1-263; 264-265 = desconocido)

```sql
SELECT 'yellow' AS tipo,
       count(*) FILTER (WHERE PULocationID NOT BETWEEN 1 AND 263) AS pu_fuera_de_zonas,
       count(*) FILTER (WHERE DOLocationID NOT BETWEEN 1 AND 263) AS do_fuera_de_zonas,
       count(*) FILTER (WHERE PULocationID IN (264, 265))         AS pu_desconocido,
       count(*) FILTER (WHERE DOLocationID IN (264, 265))         AS do_desconocido
FROM yellow
UNION ALL
SELECT 'green',
       count(*) FILTER (WHERE PULocationID NOT BETWEEN 1 AND 263),
       count(*) FILTER (WHERE DOLocationID NOT BETWEEN 1 AND 263),
       count(*) FILTER (WHERE PULocationID IN (264, 265)),
       count(*) FILTER (WHERE DOLocationID IN (264, 265))
FROM green;
```

Tiempo: 0.95 s

| tipo | pu_fuera_de_zonas | do_fuera_de_zonas | pu_desconocido | do_desconocido |
|---|---|---|---|---|
| yellow | 195877 | 548394 | 195877 | 548394 |
| green | 3013 | 13837 | 3013 | 13837 |

## Q3.6i Origen de los registros con nulos (mismas filas en varias columnas)

```sql
SELECT 'yellow' AS tipo, VendorID, payment_type,
       count(*) AS registros_con_nulos,
       count(*) FILTER (WHERE passenger_count IS NULL AND RatecodeID IS NULL
                          AND store_and_fwd_flag IS NULL AND congestion_surcharge IS NULL) AS nulos_simultaneos,
       round(avg(total_amount), 2) AS total_promedio
FROM yellow
WHERE passenger_count IS NULL
GROUP BY ALL
UNION ALL
SELECT 'green', VendorID, payment_type,
       count(*),
       count(*) FILTER (WHERE passenger_count IS NULL AND RatecodeID IS NULL
                          AND trip_type IS NULL AND congestion_surcharge IS NULL),
       round(avg(total_amount), 2)
FROM green
WHERE passenger_count IS NULL
GROUP BY ALL
ORDER BY tipo DESC, registros_con_nulos DESC;
```

Tiempo: 0.88 s

| tipo | VendorID | payment_type | registros_con_nulos | nulos_simultaneos | total_promedio |
|---|---|---|---|---|---|
| yellow | 2 | 0 | 9986526 | 9986526 | 30.22 |
| yellow | 1 | 0 | 1759935 | 1759935 | 27.42 |
| yellow | 6 | 0 | 61459 | 61459 | 32.07 |
| green | 2 | NULL | 36615 | 36615 | 33.01 |
| green | 6 | NULL | 34847 | 34847 | 29.41 |
| green | 1 | NULL | 1641 | 1641 | 24.6 |
