-- =============================================================================
-- Ejercicio 8 - Validacion de 2025 y comparacion de 2024, 2025 y 2026
--
-- Lee directamente los Parquet con las vistas del Ejercicio 4.
--
-- Ejecutar:  python scripts/run_sql.py sql/ex8_tres_anios.sql
--
-- include: sql/ex4_analisis.sql
-- =============================================================================

-- name: Q8.1 Archivos y registros por tipo y anio
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    split_part(replace(file_name, '\', '/'), '/', 4) AS anio,
    count(*)                                         AS archivos,
    sum(num_rows)                                    AS registros
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo DESC, anio;

-- name: Q8.2 Resumen por anio y tipo (enero-agosto, viajes validos)
SELECT
    tipo,
    anio,
    round(count(*) / count(DISTINCT pickup::DATE))                              AS viajes_por_dia,
    round(avg(total_amount), 2)                                                 AS total_promedio,
    median(fare_amount)                                                         AS tarifa_mediana,
    round(median(velocidad_mph), 1)                                             AS velocidad_mediana,
    round(100.0 * count(*) FILTER (WHERE payment_type = 1) / count(*), 1)       AS pct_tarjeta,
    round(100.0 * count(*) FILTER (WHERE coalesce(payment_type, 0) = 0) / count(*), 1) AS pct_sin_info_pago,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee > 0) / count(*), 1) AS pct_con_cuota_cbd
FROM viajes_validos
WHERE month(pickup) <= 8
GROUP BY tipo, anio
ORDER BY tipo DESC, anio;

-- name: Q8.3 Cuota de congestion CBD por mes (amarillos)
SELECT
    mes_archivo                                                                 AS mes,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee > 0) / count(*), 1) AS pct_con_cuota,
    round(avg(cbd_congestion_fee), 2)                                           AS cuota_promedio
FROM viajes_validos
WHERE tipo = 'yellow' AND anio >= 2025
GROUP BY mes
ORDER BY mes;

-- name: Q8.4 Registros excluidos por motivo y anio (% de los registros del anio)
SELECT
    motivo_exclusion                                                                     AS motivo,
    round(100.0 * count(*) FILTER (WHERE anio = 2024) / any_value(t.n2024), 2)           AS pct_2024,
    round(100.0 * count(*) FILTER (WHERE anio = 2025) / any_value(t.n2025), 2)           AS pct_2025,
    round(100.0 * count(*) FILTER (WHERE anio = 2026) / any_value(t.n2026), 2)           AS pct_2026
FROM viajes,
     (SELECT count(*) FILTER (WHERE anio = 2024) AS n2024,
             count(*) FILTER (WHERE anio = 2025) AS n2025,
             count(*) FILTER (WHERE anio = 2026) AS n2026
      FROM viajes) t
WHERE motivo_exclusion IS NOT NULL
GROUP BY motivo
ORDER BY pct_2025 DESC;
