-- =============================================================================
-- Ejercicio 6 - Consultas del benchmark Parquet vs. tabla DuckDB
--
-- Las consultas usan los nombres viajes / viajes_validos / zonas. El script
-- scripts/benchmark.py las ejecuta dos veces: con esos nombres como vistas
-- sobre los Parquet (Ejercicio 4) y como tablas en data/processed/*.duckdb.
--
-- Ejecutar:  python scripts/benchmark.py
-- =============================================================================

-- name: B1 Conteo de viajes validos por tipo
SELECT tipo, count(*) AS viajes
FROM viajes_validos
GROUP BY tipo;

-- name: B2 Volumen mensual e ingresos por tipo (Q4.1)
SELECT mes_archivo AS mes, tipo, count(*) AS viajes,
       round(sum(total_amount) / 1e6, 2) AS ingresos_musd
FROM viajes_validos
GROUP BY ALL
ORDER BY tipo, mes;

-- name: B3 Medianas del viaje tipico por tipo (Q4.4)
SELECT tipo,
       median(trip_distance) AS distancia_mediana,
       median(duracion_min)  AS duracion_mediana,
       median(fare_amount)   AS tarifa_mediana
FROM viajes_validos
GROUP BY tipo;

-- name: B4 Borough de origen con join a zonas (Q4.6)
SELECT z.Borough AS borough, tipo, count(*) AS viajes
FROM viajes_validos v
JOIN zonas z ON z.LocationID = v.PULocationID
GROUP BY ALL
ORDER BY viajes DESC;

-- name: B5 Filtro selectivo: primera semana de enero 2026
SELECT pickup::DATE AS fecha, count(*) AS viajes, round(avg(total_amount), 2) AS total_promedio
FROM viajes_validos
WHERE pickup >= TIMESTAMP '2026-01-01' AND pickup < TIMESTAMP '2026-01-08'
GROUP BY fecha
ORDER BY fecha;
