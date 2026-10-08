-- =============================================================================
-- Ejercicio 4 - Analisis exploratorio con DuckDB
--
-- Lee directamente los Parquet de data/raw/ y la tabla de zonas
-- data/raw/taxi_zone_lookup.csv. Las vistas no copian datos.
--
-- Ejecutar:  python scripts/run_sql.py sql/ex4_analisis.sql
--
-- Vistas:
--   viajes          amarillos + verdes con columnas normalizadas y una columna
--                   `motivo_exclusion` (NULL si el viaje es valido).
--   viajes_validos  solo los viajes que pasan las reglas de calidad definidas
--                   a partir del Ejercicio 3.
--   zonas           tabla de zonas de la TLC.
--
-- Los patrones */*.parquet incluyen cualquier anio descargado, por lo que las
-- consultas no dependen del anio.
-- =============================================================================

CREATE OR REPLACE VIEW zonas AS
SELECT * FROM read_csv('data/raw/taxi_zone_lookup.csv', header = true);

CREATE OR REPLACE VIEW viajes AS
WITH base AS (
    SELECT 'yellow' AS tipo,
           regexp_extract(filename, '(\d{4}-\d{2})', 1) AS mes_archivo,
           tpep_pickup_datetime AS pickup, tpep_dropoff_datetime AS dropoff,
           VendorID, passenger_count, trip_distance, RatecodeID, PULocationID, DOLocationID,
           payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount,
           improvement_surcharge, total_amount, congestion_surcharge,
           Airport_fee AS airport_fee,
           -- La cuota CBD empezo en enero de 2025: en archivos anteriores la columna
           -- no existe (NULL por union_by_name) y equivale a 0 USD cobrados (Ejercicio 5.7).
           coalesce(cbd_congestion_fee, 0) AS cbd_congestion_fee
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true)
    UNION ALL
    SELECT 'green',
           regexp_extract(filename, '(\d{4}-\d{2})', 1),
           lpep_pickup_datetime, lpep_dropoff_datetime,
           VendorID, passenger_count, trip_distance, RatecodeID, PULocationID, DOLocationID,
           payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount,
           improvement_surcharge, total_amount, congestion_surcharge,
           0.0, coalesce(cbd_congestion_fee, 0)
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true)
)
SELECT *,
       left(mes_archivo, 4)::INTEGER AS anio,
       date_diff('second', pickup, dropoff) / 60.0 AS duracion_min,
       CASE
           WHEN strftime(pickup, '%Y-%m') <> mes_archivo         THEN 'fecha fuera del mes del archivo'
           WHEN dropoff <= pickup                               THEN 'duracion <= 0'
           WHEN dropoff - pickup < INTERVAL 1 MINUTE            THEN 'duracion < 1 min'
           WHEN dropoff - pickup > INTERVAL 6 HOUR              THEN 'duracion > 6 h'
           WHEN trip_distance <= 0                              THEN 'distancia = 0'
           WHEN trip_distance > 100                             THEN 'distancia > 100 mi'
           WHEN fare_amount < 0 OR total_amount < 0             THEN 'monto negativo'
           WHEN total_amount >= 1000                            THEN 'total >= 1000'
       END AS motivo_exclusion
FROM base;

CREATE OR REPLACE VIEW viajes_validos AS
SELECT * EXCLUDE (motivo_exclusion),
       trip_distance / (duracion_min / 60.0) AS velocidad_mph
FROM viajes
WHERE motivo_exclusion IS NULL;

-- name: Q4.1 Volumen mensual de viajes e ingresos por tipo
SELECT
    mes_archivo                               AS mes,
    tipo,
    count(*)                                  AS viajes,
    round(count(*) / day(last_day(min(pickup)::DATE)), 0) AS viajes_por_dia,
    round(sum(total_amount) / 1e6, 2)         AS ingresos_musd,
    round(avg(total_amount), 2)               AS total_promedio
FROM viajes_validos
GROUP BY ALL
ORDER BY tipo DESC, mes;

-- name: Q4.2 Distribucion de viajes por hora del dia (% del total de cada tipo)
SELECT
    hour(pickup)                                                               AS hora,
    round(100.0 * count(*) FILTER (WHERE tipo = 'yellow')
          / sum(count(*) FILTER (WHERE tipo = 'yellow')) OVER (), 2)           AS pct_yellow,
    round(100.0 * count(*) FILTER (WHERE tipo = 'green')
          / sum(count(*) FILTER (WHERE tipo = 'green')) OVER (), 2)            AS pct_green,
    round(median(duracion_min) FILTER (WHERE tipo = 'yellow'), 1)              AS duracion_mediana_yellow,
    round(median(velocidad_mph) FILTER (WHERE tipo = 'yellow'), 1)             AS velocidad_mediana_yellow
FROM viajes_validos
GROUP BY hora
ORDER BY hora;

-- name: Q4.3 Viajes promedio por dia de la semana
WITH por_dia AS (
    SELECT tipo, pickup::DATE AS fecha, count(*) AS viajes
    FROM viajes_validos
    GROUP BY ALL
)
SELECT
    isodow(fecha)                     AS num_dia,
    dayname(fecha)                    AS dia,
    tipo,
    count(*)                          AS dias_observados,
    round(avg(viajes), 0)             AS viajes_promedio_dia,
    round(100.0 * avg(viajes) / avg(avg(viajes)) OVER (PARTITION BY tipo) - 100, 1) AS pct_vs_promedio
FROM por_dia
GROUP BY num_dia, dia, tipo
ORDER BY tipo DESC, num_dia;

-- name: Q4.4 Caracteristicas del viaje tipico por tipo de taxi
SELECT
    tipo,
    count(*)                                       AS viajes,
    round(median(trip_distance), 2)                AS distancia_mediana_mi,
    round(avg(trip_distance), 2)                   AS distancia_promedio_mi,
    round(median(duracion_min), 1)                 AS duracion_mediana_min,
    round(median(velocidad_mph), 1)                AS velocidad_mediana_mph,
    round(avg(passenger_count), 2)                 AS pasajeros_promedio,
    round(100.0 * count(*) FILTER (WHERE passenger_count = 1)
          / count(passenger_count), 1)             AS pct_un_pasajero,
    round(median(fare_amount), 2)                  AS tarifa_mediana,
    round(median(total_amount), 2)                 AS total_mediano,
    round(median(fare_amount / trip_distance), 2)  AS tarifa_por_milla_mediana
FROM viajes_validos
GROUP BY tipo
ORDER BY tipo DESC;

-- name: Q4.5 Distribucion de la distancia del viaje (% por rango)
SELECT
    CASE
        WHEN trip_distance < 1  THEN '1) < 1 mi'
        WHEN trip_distance < 2  THEN '2) 1-2 mi'
        WHEN trip_distance < 5  THEN '3) 2-5 mi'
        WHEN trip_distance < 10 THEN '4) 5-10 mi'
        WHEN trip_distance < 20 THEN '5) 10-20 mi'
        ELSE                         '6) >= 20 mi'
    END                                                                  AS rango_distancia,
    round(100.0 * count(*) FILTER (WHERE tipo = 'yellow')
          / sum(count(*) FILTER (WHERE tipo = 'yellow')) OVER (), 1)     AS pct_yellow,
    round(100.0 * count(*) FILTER (WHERE tipo = 'green')
          / sum(count(*) FILTER (WHERE tipo = 'green')) OVER (), 1)      AS pct_green,
    round(median(total_amount) FILTER (WHERE tipo = 'yellow'), 2)        AS total_mediano_yellow,
    round(median(total_amount) FILTER (WHERE tipo = 'green'), 2)         AS total_mediano_green
FROM viajes_validos
GROUP BY ALL
ORDER BY rango_distancia;

-- name: Q4.6 Borough de origen de los viajes (% por tipo)
SELECT
    coalesce(z.Borough, 'Sin zona')                                      AS borough,
    round(100.0 * count(*) FILTER (WHERE tipo = 'yellow')
          / sum(count(*) FILTER (WHERE tipo = 'yellow')) OVER (), 2)     AS pct_yellow,
    round(100.0 * count(*) FILTER (WHERE tipo = 'green')
          / sum(count(*) FILTER (WHERE tipo = 'green')) OVER (), 2)      AS pct_green
FROM viajes_validos v
LEFT JOIN zonas z ON z.LocationID = v.PULocationID
GROUP BY ALL
ORDER BY pct_yellow DESC;

-- name: Q4.7 Diez zonas de abordaje con mas viajes por tipo
SELECT tipo, ranking, borough, zona, viajes, pct_del_tipo
FROM (
    SELECT
        tipo,
        row_number() OVER (PARTITION BY tipo ORDER BY count(*) DESC)     AS ranking,
        z.Borough                                                        AS borough,
        z.Zone                                                           AS zona,
        count(*)                                                         AS viajes,
        round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo), 2) AS pct_del_tipo
    FROM viajes_validos v
    JOIN zonas z ON z.LocationID = v.PULocationID
    GROUP BY tipo, z.Borough, z.Zone
)
WHERE ranking <= 10
ORDER BY tipo DESC, ranking;

-- name: Q4.8 Forma de pago por tipo de taxi (% de viajes)
SELECT
    CASE coalesce(payment_type, 0)
        WHEN 0 THEN '0 sin informacion / flex fare'
        WHEN 1 THEN '1 tarjeta de credito'
        WHEN 2 THEN '2 efectivo'
        WHEN 3 THEN '3 sin cargo'
        WHEN 4 THEN '4 disputa'
        WHEN 5 THEN '5 desconocido'
        WHEN 6 THEN '6 viaje anulado'
    END                                                                  AS forma_pago,
    round(100.0 * count(*) FILTER (WHERE tipo = 'yellow')
          / sum(count(*) FILTER (WHERE tipo = 'yellow')) OVER (), 2)     AS pct_yellow,
    round(100.0 * count(*) FILTER (WHERE tipo = 'green')
          / sum(count(*) FILTER (WHERE tipo = 'green')) OVER (), 2)      AS pct_green,
    round(100.0 * count(*) FILTER (WHERE tipo = 'yellow' AND payment_type <> 0)
          / sum(count(*) FILTER (WHERE tipo = 'yellow' AND payment_type <> 0)) OVER (), 2) AS pct_yellow_con_info
FROM viajes_validos
GROUP BY ALL
ORDER BY forma_pago;

-- name: Q4.9 Propinas segun la forma de pago
SELECT
    tipo,
    CASE coalesce(payment_type, 0)
        WHEN 0 THEN 'sin informacion' WHEN 1 THEN 'tarjeta' WHEN 2 THEN 'efectivo'
        ELSE 'otro'
    END                                                       AS forma_pago,
    count(*)                                                  AS viajes,
    round(100.0 * count(*) FILTER (WHERE tip_amount > 0) / count(*), 1) AS pct_con_propina,
    round(avg(tip_amount), 2)                                 AS propina_promedio,
    round(100.0 * sum(tip_amount) / sum(fare_amount), 1)      AS propina_pct_de_tarifa,
    round(median(100.0 * tip_amount / fare_amount)
          FILTER (WHERE tip_amount > 0 AND fare_amount > 0), 1) AS propina_pct_mediana_si_deja
FROM viajes_validos
GROUP BY ALL
ORDER BY tipo DESC, viajes DESC;

-- name: Q4.10 Propina con tarjeta segun la hora del dia
SELECT
    hour(pickup)                                                       AS hora,
    round(100.0 * sum(tip_amount) / sum(fare_amount), 1)               AS propina_pct_tarifa,
    round(100.0 * count(*) FILTER (WHERE tip_amount > 0) / count(*), 1) AS pct_con_propina,
    round(avg(trip_distance), 2)                                       AS distancia_promedio
FROM viajes_validos
WHERE tipo = 'yellow' AND payment_type = 1 AND fare_amount > 0
GROUP BY hora
ORDER BY hora;

-- name: Q4.11 Composicion del monto total (promedio por viaje, USD)
SELECT
    tipo,
    round(avg(fare_amount), 2)            AS tarifa,
    round(avg(extra), 2)                  AS extra,
    round(avg(mta_tax), 2)                AS mta_tax,
    round(avg(improvement_surcharge), 2)  AS improvement_surcharge,
    round(avg(congestion_surcharge), 2)   AS congestion_surcharge,
    round(avg(cbd_congestion_fee), 2)     AS cbd_congestion_fee,
    round(avg(airport_fee), 2)            AS airport_fee,
    round(avg(tolls_amount), 2)           AS peajes,
    round(avg(tip_amount), 2)             AS propina,
    round(avg(total_amount), 2)           AS total,
    round(100.0 * sum(fare_amount) / sum(total_amount), 1) AS pct_tarifa_en_total
FROM viajes_validos
GROUP BY tipo
ORDER BY tipo DESC;

-- name: Q4.12 Viajes de aeropuerto y cuota de congestion CBD
SELECT
    tipo,
    round(100.0 * count(*) FILTER (WHERE PULocationID IN (1, 132, 138)
                                      OR DOLocationID IN (1, 132, 138)) / count(*), 2) AS pct_viajes_aeropuerto,
    round(100.0 * sum(total_amount) FILTER (WHERE PULocationID IN (1, 132, 138)
                                              OR DOLocationID IN (1, 132, 138))
          / sum(total_amount), 2)                                                     AS pct_ingresos_aeropuerto,
    round(median(total_amount) FILTER (WHERE PULocationID IN (1, 132, 138)
                                          OR DOLocationID IN (1, 132, 138)), 2)       AS total_mediano_aeropuerto,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee > 0) / count(*), 2)      AS pct_con_cuota_cbd,
    round(sum(cbd_congestion_fee) / 1e6, 2)                                           AS cuota_cbd_musd
FROM viajes_validos
GROUP BY tipo
ORDER BY tipo DESC;

-- name: Q4.13 Registros excluidos por motivo (valores atipicos e inconsistencias)
SELECT
    tipo,
    coalesce(motivo_exclusion, '(valido)')                       AS motivo,
    count(*)                                                     AS registros,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo), 2) AS pct_del_tipo
FROM viajes
GROUP BY tipo, motivo
ORDER BY tipo DESC, registros DESC;

-- name: Q4.14 Valores atipicos entre viajes validos (regla IQR y velocidad)
WITH limites AS (
    SELECT tipo,
           quantile_cont(fare_amount / trip_distance, 0.25) AS q1,
           quantile_cont(fare_amount / trip_distance, 0.75) AS q3
    FROM viajes_validos
    GROUP BY tipo
)
SELECT
    v.tipo,
    round(l.q1, 2)                                                       AS tarifa_milla_q1,
    round(l.q3, 2)                                                       AS tarifa_milla_q3,
    round(l.q3 + 1.5 * (l.q3 - l.q1), 2)                                 AS limite_superior_iqr,
    count(*) FILTER (WHERE v.fare_amount / v.trip_distance > l.q3 + 1.5 * (l.q3 - l.q1)) AS atipicos_tarifa_milla,
    round(100.0 * count(*) FILTER (WHERE v.fare_amount / v.trip_distance > l.q3 + 1.5 * (l.q3 - l.q1))
          / count(*), 2)                                                 AS pct_atipicos_tarifa_milla,
    count(*) FILTER (WHERE v.velocidad_mph > 80)                         AS velocidad_mayor_80mph,
    count(*) FILTER (WHERE v.fare_amount = 0)                            AS tarifa_cero,
    count(*) FILTER (WHERE v.RatecodeID = 5)                             AS tarifa_negociada
FROM viajes_validos v
JOIN limites l USING (tipo)
GROUP BY ALL
ORDER BY v.tipo DESC;
