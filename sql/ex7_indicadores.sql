-- =============================================================================
-- Ejercicio 7 - Indicadores del tablero
--
-- Se ejecutan sobre la base materializada data/processed/taxis.duckdb
-- (tabla viajes, vista viajes_validos y tabla zonas, ver scripts/construir_db.py).
-- Son las mismas consultas que usan las tarjetas de Metabase
-- (scripts/metabase_tablero.py).
--
-- Ejecutar:  python scripts/run_sql.py sql/ex7_indicadores.sql --db data/processed/taxis.duckdb
--
-- Ninguna consulta fija el anio: agrupan por mes o por anio, asi que al
-- reconstruir la base con anios nuevos los indicadores se actualizan solos.
-- =============================================================================

-- name: I1 Viajes por dia segun mes y tipo
SELECT date_trunc('month', pickup)::DATE           AS mes,
       tipo,
       round(count(*) / count(DISTINCT pickup::DATE)) AS viajes_por_dia
FROM viajes_validos
GROUP BY ALL
ORDER BY mes, tipo;

-- name: I2 Viajes por hora del dia (% del total de cada tipo)
SELECT hour(pickup) AS hora,
       tipo,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo), 2) AS pct_viajes
FROM viajes_validos
GROUP BY hora, tipo
ORDER BY hora, tipo;

-- name: I3 Viajes por dia de la semana (% sobre el promedio del tipo)
WITH por_fecha AS (
    SELECT tipo, pickup::DATE AS fecha, count(*) AS viajes
    FROM viajes_validos
    GROUP BY ALL
)
SELECT isodow(fecha) || ' ' || dayname(fecha) AS dia,
       tipo,
       round(100.0 * avg(viajes) / avg(avg(viajes)) OVER (PARTITION BY tipo) - 100, 1) AS pct_vs_promedio
FROM por_fecha
GROUP BY dia, tipo
ORDER BY dia, tipo;

-- name: I4 Tarifa mediana y total promedio por mes (amarillos)
SELECT date_trunc('month', pickup)::DATE AS mes,
       median(fare_amount)                AS tarifa_mediana,
       round(avg(total_amount), 2)        AS total_promedio
FROM viajes_validos
WHERE tipo = 'yellow'
GROUP BY mes
ORDER BY mes;

-- name: I5 Forma de pago por anio y tipo (% de viajes)
SELECT anio || ' ' || tipo AS grupo,
       CASE coalesce(payment_type, 0)
           WHEN 0 THEN 'sin informacion' WHEN 1 THEN 'tarjeta'
           WHEN 2 THEN 'efectivo' ELSE 'otro'
       END                 AS forma_pago,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY anio, tipo), 1) AS pct_viajes
FROM viajes_validos
GROUP BY anio, tipo, forma_pago
ORDER BY grupo, forma_pago;

-- name: I6 Propina con tarjeta como % de la tarifa por mes y tipo
SELECT date_trunc('month', pickup)::DATE                  AS mes,
       tipo,
       round(100.0 * sum(tip_amount) / sum(fare_amount), 1) AS propina_pct_tarifa
FROM viajes_validos
WHERE payment_type = 1 AND fare_amount > 0
GROUP BY ALL
ORDER BY mes, tipo;

-- name: I7 Borough de origen por anio (% de viajes del anio)
SELECT coalesce(z.Borough, 'Sin zona') AS borough,
       anio::VARCHAR                   AS anio,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY anio), 2) AS pct_viajes
FROM viajes_validos v
LEFT JOIN zonas z ON z.LocationID = v.PULocationID
GROUP BY z.Borough, v.anio
ORDER BY borough, anio;

-- name: I8 Velocidad mediana por hora del dia y anio (amarillos)
SELECT hour(pickup)               AS hora,
       anio::VARCHAR              AS anio,
       round(median(velocidad_mph), 1) AS velocidad_mediana_mph
FROM viajes_validos
WHERE tipo = 'yellow'
GROUP BY ALL
ORDER BY hora, anio;

-- name: I9 Peso de los viajes de aeropuerto por anio (amarillos)
SELECT anio::VARCHAR AS anio,
       round(100.0 * count(*) FILTER (WHERE PULocationID IN (1, 132, 138) OR DOLocationID IN (1, 132, 138))
             / count(*), 1)                                        AS pct_viajes,
       round(100.0 * sum(total_amount) FILTER (WHERE PULocationID IN (1, 132, 138) OR DOLocationID IN (1, 132, 138))
             / sum(total_amount), 1)                               AS pct_ingresos
FROM viajes_validos
WHERE tipo = 'yellow'
GROUP BY anio
ORDER BY anio;

-- name: I10 Calidad de datos por mes (% de registros)
SELECT strptime(mes_archivo, '%Y-%m')::DATE                                     AS mes,
       round(100.0 * count(*) FILTER (WHERE motivo_exclusion IS NOT NULL) / count(*), 2) AS pct_excluidos,
       round(100.0 * count(*) FILTER (WHERE coalesce(payment_type, 0) = 0) / count(*), 2) AS pct_sin_info_pago
FROM viajes
GROUP BY mes
ORDER BY mes;
