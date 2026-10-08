-- =============================================================================
-- Ejercicio 3 - Consultas directas sobre archivos Parquet
--
-- Todas las consultas leen los archivos Parquet de data/raw/ directamente con
-- read_parquet() / parquet_metadata(); no se importa nada a una tabla.
-- Las rutas son relativas a la raiz del proyecto (/workspace en el contenedor).
--
-- Ejecutar:  python scripts/run_sql.py sql/ex3_exploracion.sql
--
-- Cada bloque "-- name:" es una consulta independiente. Las vistas solo son un
-- alias de la lectura del archivo (no copian datos): se vuelven a leer los
-- Parquet cada vez que se consultan.
--
-- union_by_name=true es necesario: desde 2026-06 la TLC agrego la columna
-- request_source, por lo que no todos los archivos tienen el mismo esquema
-- (ver Q3.4b). Sin esta opcion DuckDB toma el esquema del primer archivo.
-- =============================================================================

CREATE OR REPLACE VIEW yellow AS
SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true);

CREATE OR REPLACE VIEW green AS
SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true);

-- name: Q3.1 Cantidad de archivos disponibles por tipo y anio
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    split_part(replace(file_name, '\', '/'), '/', 4) AS anio,
    count(*)                                         AS archivos,
    round(sum(file_size_bytes) / 1024 / 1024, 1)     AS mib
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo, anio;

-- name: Q3.2a Cantidad de registros segun los metadatos Parquet (sin leer filas)
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    sum(num_rows)                                    AS registros
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo;

-- name: Q3.2b Cantidad de registros por archivo (conteo leyendo los datos)
SELECT 'yellow' AS tipo, regexp_extract(filename, '(\d{4}-\d{2})', 1) AS mes, count(*) AS registros
FROM yellow GROUP BY ALL
UNION ALL
SELECT 'green', regexp_extract(filename, '(\d{4}-\d{2})', 1), count(*)
FROM green GROUP BY ALL
ORDER BY tipo DESC, mes;

-- name: Q3.3 Columnas presentes y en cuantos archivos aparece cada una
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    name                                             AS columna,
    count(*)                                         AS archivos_con_columna
FROM parquet_schema('data/raw/*/*/*.parquet')
WHERE name <> 'schema'
GROUP BY ALL
ORDER BY tipo DESC, archivos_con_columna, columna;

-- name: Q3.4a Tipos de datos de las columnas (taxis amarillos)
DESCRIBE SELECT * EXCLUDE (filename) FROM yellow;

-- name: Q3.4b Tipos de datos de las columnas (taxis verdes)
DESCRIBE SELECT * EXCLUDE (filename) FROM green;

-- name: Q3.4c Archivos que contienen la columna request_source
SELECT
    regexp_extract(file_name, '([a-z]+_tripdata_\d{4}-\d{2})', 1) AS archivo,
    count(*) FILTER (WHERE name = 'request_source')               AS tiene_request_source,
    count(*) - 1                                                  AS columnas
FROM parquet_schema('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY archivo;

-- name: Q3.5a Muestra de registros (amarillos)
SELECT * EXCLUDE (filename)
FROM yellow
USING SAMPLE 5 ROWS (reservoir, 42);

-- name: Q3.5b Muestra de registros (verdes)
SELECT * EXCLUDE (filename)
FROM green
USING SAMPLE 5 ROWS (reservoir, 42);

-- name: Q3.6a Valores nulos por columna (amarillos)
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

-- name: Q3.6b Valores nulos por columna (verdes)
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

-- name: Q3.6c Registros con fecha de abordaje fuera del mes del archivo
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

-- name: Q3.6d Inconsistencias de tiempo, distancia, pasajeros y montos
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

-- name: Q3.6e Distribucion de valores extremos de distancia y monto total
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

-- name: Q3.6f Codigos categoricos fuera del diccionario de la TLC
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

-- name: Q3.6g Registros completamente duplicados
SELECT 'yellow' AS tipo, count(*) - (SELECT count(*) FROM (SELECT DISTINCT * EXCLUDE (filename) FROM yellow)) AS duplicados
FROM yellow
UNION ALL
SELECT 'green', count(*) - (SELECT count(*) FROM (SELECT DISTINCT * EXCLUDE (filename) FROM green))
FROM green;

-- name: Q3.6h Identificadores de zona fuera de las zonas validas (1-263; 264-265 = desconocido)
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

-- name: Q3.6i Origen de los registros con nulos (mismas filas en varias columnas)
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
