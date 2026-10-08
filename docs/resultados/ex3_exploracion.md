# Resultados de `sql/ex3_exploracion.sql`

Generado con `python scripts/run_sql.py sql/ex3_exploracion.sql` el 2026-10-08 13:09 (DuckDB 1.5.5).

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

Tiempo: 0.03 s

| tipo | anio | archivos | mib |
|---|---|---|---|
| green | 2026 | 8 | 7.9 |
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

Tiempo: 0.04 s

| tipo | registros |
|---|---|
| green | 337114 |
| yellow | 29703355 |

## Q3.2b Cantidad de registros por archivo (conteo leyendo los datos)

```sql
SELECT 'yellow' AS tipo, regexp_extract(filename, '(\d{4}-\d{2})', 1) AS mes, count(*) AS registros
FROM yellow GROUP BY ALL
UNION ALL
SELECT 'green', regexp_extract(filename, '(\d{4}-\d{2})', 1), count(*)
FROM green GROUP BY ALL
ORDER BY tipo DESC, mes;
```

Tiempo: 0.08 s

| tipo | mes | registros |
|---|---|---|
| yellow | 2026-01 | 3724889 |
| yellow | 2026-02 | 3399866 |
| yellow | 2026-03 | 3952451 |
| yellow | 2026-04 | 3831240 |
| yellow | 2026-05 | 4090836 |
| yellow | 2026-06 | 3837248 |
| yellow | 2026-07 | 3530109 |
| yellow | 2026-08 | 3336716 |
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

Tiempo: 0.04 s

| tipo | columna | archivos_con_columna |
|---|---|---|
| yellow | request_source | 3 |
| yellow | Airport_fee | 8 |
| yellow | DOLocationID | 8 |
| yellow | PULocationID | 8 |
| yellow | RatecodeID | 8 |
| yellow | VendorID | 8 |
| yellow | cbd_congestion_fee | 8 |
| yellow | congestion_surcharge | 8 |
| yellow | extra | 8 |
| yellow | fare_amount | 8 |
| yellow | improvement_surcharge | 8 |
| yellow | mta_tax | 8 |
| yellow | passenger_count | 8 |
| yellow | payment_type | 8 |
| yellow | store_and_fwd_flag | 8 |
| yellow | tip_amount | 8 |
| yellow | tolls_amount | 8 |
| yellow | total_amount | 8 |
| yellow | tpep_dropoff_datetime | 8 |
| yellow | tpep_pickup_datetime | 8 |
| yellow | trip_distance | 8 |
| green | request_source | 3 |
| green | DOLocationID | 8 |
| green | PULocationID | 8 |
| green | RatecodeID | 8 |
| green | VendorID | 8 |
| green | cbd_congestion_fee | 8 |
| green | congestion_surcharge | 8 |
| green | ehail_fee | 8 |
| green | extra | 8 |
| green | fare_amount | 8 |
| green | improvement_surcharge | 8 |
| green | lpep_dropoff_datetime | 8 |
| green | lpep_pickup_datetime | 8 |
| green | mta_tax | 8 |
| green | passenger_count | 8 |
| green | payment_type | 8 |
| green | store_and_fwd_flag | 8 |
| green | tip_amount | 8 |
| green | tolls_amount | 8 |
| green | total_amount | 8 |
| green | trip_distance | 8 |
| green | trip_type | 8 |

## Q3.4a Tipos de datos de las columnas (taxis amarillos)

```sql
DESCRIBE SELECT * EXCLUDE (filename) FROM yellow;
```

Tiempo: 0.02 s

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

Tiempo: 0.02 s

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

Tiempo: 0.03 s

| archivo | tiene_request_source | columnas |
|---|---|---|
| green_tripdata_2026-01 | 0 | 21 |
| green_tripdata_2026-02 | 0 | 21 |
| green_tripdata_2026-03 | 0 | 21 |
| green_tripdata_2026-04 | 0 | 21 |
| green_tripdata_2026-05 | 0 | 21 |
| green_tripdata_2026-06 | 1 | 22 |
| green_tripdata_2026-07 | 1 | 22 |
| green_tripdata_2026-08 | 1 | 22 |
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

Tiempo: 0.24 s

| VendorID | tpep_pickup_datetime | tpep_dropoff_datetime | passenger_count | trip_distance | RatecodeID | store_and_fwd_flag | PULocationID | DOLocationID | payment_type | fare_amount | extra | mta_tax | tip_amount | tolls_amount | improvement_surcharge | total_amount | congestion_surcharge | Airport_fee | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-01-01 00:34:45 | 2026-01-01 00:40:15 | 4 | 0.9 | 1 | N | 262 | 141 | 1 | 7.9 | 3.5 | 0.5 | 3.2 | 0 | 1 | 16.1 | 2.5 | 0 | 0 | NULL |
| 1 | 2026-01-01 00:06:07 | 2026-01-01 00:20:20 | 2 | 1.9 | 1 | N | 231 | 90 | 1 | 14.2 | 4.25 | 0.5 | 3.95 | 0 | 1 | 23.9 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-01-01 03:15:42 | 2026-01-01 03:20:33 | 1 | 1.15 | 1 | N | 263 | 140 | 1 | 7.2 | 1 | 0.5 | 2.44 | 0 | 1 | 14.64 | 2.5 | 0 | 0 | NULL |
| 2 | 2026-01-01 04:25:35 | 2026-01-01 04:38:18 | 1 | 3.69 | 1 | N | 107 | 143 | 1 | 17.7 | 1 | 0.5 | 4.69 | 0 | 1 | 28.14 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-01-01 06:33:56 | 2026-01-01 06:55:37 | 2 | 10.27 | 2 | N | 68 | 138 | 2 | 70 | 0 | 0.5 | 0 | 6.94 | 1 | 81.69 | 2.5 | 0 | 0.75 | NULL |

## Q3.5b Muestra de registros (verdes)

```sql
SELECT * EXCLUDE (filename)
FROM green
USING SAMPLE 5 ROWS (reservoir, 42);
```

Tiempo: 0.09 s

| VendorID | lpep_pickup_datetime | lpep_dropoff_datetime | store_and_fwd_flag | RatecodeID | PULocationID | DOLocationID | passenger_count | trip_distance | fare_amount | extra | mta_tax | tip_amount | tolls_amount | ehail_fee | improvement_surcharge | total_amount | payment_type | trip_type | congestion_surcharge | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2026-01-02 05:43:34 | 2026-01-02 05:44:09 | N | 5 | 34 | 34 | 2 | 0.4 | 70 | 0 | 0 | 14.2 | 0 | NULL | 1 | 85.2 | 1 | 2 | 0 | 0 | NULL |
| 2 | 2026-01-02 21:02:00 | 2026-01-02 21:07:42 | N | 1 | 74 | 41 | 1 | 1.17 | 7.9 | 1 | 0.5 | 2.08 | 0 | NULL | 1 | 12.48 | 1 | 1 | 0 | 0 | NULL |
| 1 | 2026-01-14 21:03:03 | 2026-01-14 21:06:16 | N | 1 | 181 | 65 | 1 | 0.6 | 5.8 | 1 | 1.5 | 0 | 0 | NULL | 1 | 8.3 | 2 | 1 | 0 | 0 | NULL |
| 2 | 2026-01-16 19:11:20 | 2026-01-16 19:29:44 | N | 1 | 74 | 151 | 1 | 2.33 | 17.7 | 2.5 | 0.5 | 4.34 | 0 | NULL | 1 | 26.04 | 1 | 1 | 0 | 0 | NULL |
| 2 | 2026-01-19 02:15:45 | 2026-01-19 02:20:57 | N | 1 | 95 | 102 | 1 | 1.35 | 8.6 | 1 | 0.5 | 1 | 0 | NULL | 1 | 12.1 | 1 | 1 | 0 | 0 | NULL |

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

Tiempo: 0.45 s

| registros | null_passenger_count | null_ratecodeid | null_store_and_fwd_flag | null_congestion_surcharge | null_airport_fee | null_request_source | pct_null_passenger_count |
|---|---|---|---|---|---|---|---|
| 29703355 | 7716688 | 7716688 | 7716688 | 7716688 | 7716688 | 26799909 | 25.98 |

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

Tiempo: 0.04 s

| registros | null_passenger_count | null_ratecodeid | null_payment_type | null_trip_type | null_congestion_surcharge | null_ehail_fee | null_request_source |
|---|---|---|---|---|---|---|---|
| 337114 | 48775 | 48775 | 48775 | 48777 | 48775 | 337114 | 317903 |

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

Tiempo: 0.90 s

| tipo | fuera_de_mes | pickup_min | pickup_max |
|---|---|---|---|
| yellow | 146 | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 |
| green | 98 | 2008-12-31 17:35:31 | 2026-08-31 23:58:28 |

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

Tiempo: 2.07 s

| tipo | registros | dropoff_antes_pickup | duracion_cero | duracion_mayor_24h | distancia_cero | distancia_negativa | distancia_mayor_100mi | pasajeros_cero | pasajeros_mas_6 | tarifa_negativa | total_negativo | total_mayor_1000 | propina_negativa |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 29703355 | 10 | 371673 | 263 | 952231 | 0 | 1223 | 91359 | 28 | 157364 | 161835 | 49 | 883 |
| green | 337114 | 5 | 229 | 4 | 12212 | 0 | 72 | 4527 | 99 | 999 | 1023 | 1 | 69 |

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

Tiempo: 3.55 s

| tipo | dist_min | dist_p50_p99_p999 | dist_max | total_min | total_p50_p99_p999 | total_max |
|---|---|---|---|---|---|---|
| yellow | 0 | [1.86, 19.5, 30.7365] | 328,522.2 | -2,560.2 | [23.58, 105.75, 184.42] | 7,053.5 |
| green | 0 | [2.07, 17.76, 30.05] | 179,830.92 | -501.5 | [20.46, 97.2, 224.7751] | 1,678.2 |

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

Tiempo: 0.92 s

| tipo | columna | valor | registros |
|---|---|---|---|
| yellow | RatecodeID | NULL | 7716688 |
| yellow | RatecodeID | 1 | 20102072 |
| yellow | RatecodeID | 2 | 694936 |
| yellow | RatecodeID | 3 | 90052 |
| yellow | RatecodeID | 4 | 67285 |
| yellow | RatecodeID | 5 | 262614 |
| yellow | RatecodeID | 6 | 15 |
| yellow | RatecodeID | 99 | 769693 |
| yellow | VendorID | 1 | 5467071 |
| yellow | VendorID | 2 | 23809774 |
| yellow | VendorID | 6 | 59390 |
| yellow | VendorID | 7 | 367120 |
| yellow | payment_type | 0 | 7716688 |
| yellow | payment_type | 1 | 18941008 |
| yellow | payment_type | 2 | 2708031 |
| yellow | payment_type | 3 | 98138 |
| yellow | payment_type | 4 | 239488 |
| yellow | payment_type | 5 | 2 |
| green | RatecodeID | NULL | 48775 |
| green | RatecodeID | 1 | 269152 |
| green | RatecodeID | 2 | 887 |
| green | RatecodeID | 3 | 203 |
| green | RatecodeID | 4 | 354 |
| green | RatecodeID | 5 | 17739 |
| green | RatecodeID | 6 | 2 |
| green | RatecodeID | 99 | 2 |
| green | VendorID | 1 | 28696 |
| green | VendorID | 2 | 273571 |
| green | VendorID | 6 | 34847 |
| green | payment_type | NULL | 48775 |
| green | payment_type | 1 | 219980 |
| green | payment_type | 2 | 65921 |
| green | payment_type | 3 | 1688 |
| green | payment_type | 4 | 750 |
| green | trip_type | NULL | 48777 |
| green | trip_type | 1 | 273386 |
| green | trip_type | 2 | 14951 |

## Q3.6g Registros completamente duplicados

```sql
SELECT 'yellow' AS tipo, count(*) - (SELECT count(*) FROM (SELECT DISTINCT * EXCLUDE (filename) FROM yellow)) AS duplicados
FROM yellow
UNION ALL
SELECT 'green', count(*) - (SELECT count(*) FROM (SELECT DISTINCT * EXCLUDE (filename) FROM green))
FROM green;
```

Tiempo: 7.39 s

| tipo | duplicados |
|---|---|
| yellow | 7 |
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

Tiempo: 0.44 s

| tipo | pu_fuera_de_zonas | do_fuera_de_zonas | pu_desconocido | do_desconocido |
|---|---|---|---|---|
| yellow | 49676 | 178136 | 49676 | 178136 |
| green | 1131 | 5600 | 1131 | 5600 |

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

Tiempo: 0.49 s

| tipo | VendorID | payment_type | registros_con_nulos | nulos_simultaneos | total_promedio |
|---|---|---|---|---|---|
| yellow | 2 | 0 | 6761917 | 6761917 | 32.88 |
| yellow | 1 | 0 | 895381 | 895381 | 30.28 |
| yellow | 6 | 0 | 59390 | 59390 | 31.74 |
| green | 6 | NULL | 34847 | 34847 | 29.41 |
| green | 2 | NULL | 13400 | 13400 | 34.2 |
| green | 1 | NULL | 528 | 528 | 24.3 |
