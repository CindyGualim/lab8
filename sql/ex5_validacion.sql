-- =============================================================================
-- Ejercicio 5 - Validacion de la incorporacion de 2024
--
-- Comprueba que los archivos de 2024 se incorporaron correctamente y que DuckDB
-- puede consultar 2024 y 2026 de forma conjunta. Lee directamente los Parquet.
--
-- Ejecutar:  python scripts/run_sql.py sql/ex5_validacion.sql
--
-- Reutiliza las vistas viajes / viajes_validos / zonas del Ejercicio 4:
-- include: sql/ex4_analisis.sql
-- =============================================================================

-- name: Q5.1 Archivos y registros por tipo y anio (metadatos Parquet)
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    split_part(replace(file_name, '\', '/'), '/', 4) AS anio,
    count(*)                                         AS archivos,
    sum(num_rows)                                    AS registros,
    round(sum(file_size_bytes) / 1024 / 1024, 1)     AS mib
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo DESC, anio;

-- name: Q5.2 Meses esperados vs. meses presentes por tipo y anio
-- Esperado: 2024 completo (12 meses) y 2026 de enero a agosto (ultimo publicado).
WITH esperados AS (
    SELECT tipo, strftime(mes, '%Y-%m') AS mes
    FROM (VALUES ('yellow'), ('green')) t(tipo),
         (SELECT unnest(generate_series(DATE '2024-01-01', DATE '2024-12-01', INTERVAL 1 MONTH))
          UNION ALL
          SELECT unnest(generate_series(DATE '2026-01-01', DATE '2026-08-01', INTERVAL 1 MONTH))) m(mes)
),
presentes AS (
    SELECT split_part(replace(file_name, '\', '/'), '/', 3)        AS tipo,
           regexp_extract(file_name, '(\d{4}-\d{2})', 1)            AS mes,
           num_rows
    FROM parquet_file_metadata('data/raw/*/*/*.parquet')
)
SELECT
    e.tipo,
    left(e.mes, 4)                                  AS anio,
    count(*)                                        AS meses_esperados,
    count(p.mes)                                    AS meses_presentes,
    coalesce(string_agg(e.mes, ', ') FILTER (WHERE p.mes IS NULL), '-') AS meses_faltantes,
    count(*) FILTER (WHERE p.num_rows = 0)          AS archivos_vacios
FROM esperados e
LEFT JOIN presentes p USING (tipo, mes)
GROUP BY ALL
ORDER BY e.tipo DESC, anio;

-- name: Q5.3 Registros por mes: metadatos vs. lectura de datos (ambos anios)
WITH metadatos AS (
    SELECT split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
           regexp_extract(file_name, '(\d{4}-\d{2})', 1)     AS mes,
           num_rows                                          AS filas_metadatos
    FROM parquet_file_metadata('data/raw/*/*/*.parquet')
),
datos AS (
    SELECT tipo, mes_archivo AS mes, count(*) AS filas_leidas
    FROM viajes
    GROUP BY ALL
)
SELECT tipo, mes, filas_metadatos, filas_leidas, filas_leidas - filas_metadatos AS diferencia
FROM metadatos
FULL JOIN datos USING (tipo, mes)
ORDER BY tipo DESC, mes;

-- name: Q5.4 Columnas que no estan presentes en todos los archivos del tipo
WITH esquema AS (
    SELECT split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
           split_part(replace(file_name, '\', '/'), '/', 4) AS anio,
           file_name, name, type
    FROM parquet_schema('data/raw/*/*/*.parquet')
    WHERE name <> 'schema'
),
totales AS (
    SELECT tipo, count(DISTINCT file_name) AS archivos_tipo
    FROM esquema
    GROUP BY tipo
)
SELECT
    e.tipo,
    e.name                                        AS columna,
    string_agg(DISTINCT e.anio, ', ' ORDER BY e.anio) AS anios_con_columna,
    count(*)                                      AS archivos_con_columna,
    any_value(t.archivos_tipo)                    AS archivos_del_tipo,
    string_agg(DISTINCT e.type, ', ')             AS tipos_fisicos
FROM esquema e
JOIN totales t USING (tipo)
GROUP BY e.tipo, e.name
HAVING count(*) < any_value(t.archivos_tipo) OR count(DISTINCT e.type) > 1
ORDER BY e.tipo DESC, columna;

-- name: Q5.5 Consulta conjunta 2024 vs 2026 (enero-agosto, viajes validos)
-- Se compara el mismo periodo (ene-ago) para no mezclar estacionalidad.
SELECT
    tipo,
    anio,
    count(*)                                                      AS viajes,
    round(count(*) / count(DISTINCT pickup::DATE), 0)             AS viajes_por_dia,
    round(sum(total_amount) / 1e6, 1)                             AS ingresos_musd,
    round(avg(total_amount), 2)                                   AS total_promedio,
    round(median(fare_amount), 2)                                 AS tarifa_mediana,
    round(median(trip_distance), 2)                               AS distancia_mediana,
    round(median(velocidad_mph), 1)                               AS velocidad_mediana,
    round(100.0 * count(*) FILTER (WHERE payment_type = 1) / count(*), 1)          AS pct_tarjeta,
    round(100.0 * count(*) FILTER (WHERE coalesce(payment_type, 0) = 0) / count(*), 1) AS pct_sin_info_pago,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee > 0) / count(*), 1)   AS pct_con_cuota_cbd
FROM viajes_validos
WHERE month(pickup) <= 8
GROUP BY tipo, anio
ORDER BY tipo DESC, anio;

-- name: Q5.6 Variacion 2026 vs 2024 (enero-agosto)
WITH por_anio AS (
    SELECT tipo, anio,
           count(*) / count(DISTINCT pickup::DATE) AS viajes_por_dia,
           avg(total_amount)                       AS total_promedio,
           median(fare_amount)                     AS tarifa_mediana,
           median(velocidad_mph)                   AS velocidad_mediana
    FROM viajes_validos
    WHERE month(pickup) <= 8
    GROUP BY tipo, anio
)
SELECT
    tipo,
    round(100.0 * (max(viajes_por_dia) FILTER (WHERE anio = 2026)
                 / max(viajes_por_dia) FILTER (WHERE anio = 2024) - 1), 1)    AS var_pct_viajes_por_dia,
    round(100.0 * (max(total_promedio) FILTER (WHERE anio = 2026)
                 / max(total_promedio) FILTER (WHERE anio = 2024) - 1), 1)    AS var_pct_total_promedio,
    round(100.0 * (max(tarifa_mediana) FILTER (WHERE anio = 2026)
                 / max(tarifa_mediana) FILTER (WHERE anio = 2024) - 1), 1)    AS var_pct_tarifa_mediana,
    round(100.0 * (max(velocidad_mediana) FILTER (WHERE anio = 2026)
                 / max(velocidad_mediana) FILTER (WHERE anio = 2024) - 1), 1) AS var_pct_velocidad_mediana
FROM por_anio
GROUP BY tipo
ORDER BY tipo DESC;

-- name: Q5.7 Calidad de datos por anio (proporcion de registros excluidos y sin informacion de pago)
SELECT
    tipo,
    anio,
    count(*)                                                                    AS registros,
    round(100.0 * count(*) FILTER (WHERE motivo_exclusion IS NOT NULL) / count(*), 2) AS pct_excluidos,
    round(100.0 * count(*) FILTER (WHERE motivo_exclusion = 'distancia = 0') / count(*), 2) AS pct_distancia_cero,
    round(100.0 * count(*) FILTER (WHERE motivo_exclusion = 'monto negativo') / count(*), 2) AS pct_monto_negativo,
    round(100.0 * count(*) FILTER (WHERE passenger_count IS NULL) / count(*), 2)     AS pct_sin_metadatos
FROM viajes
GROUP BY tipo, anio
ORDER BY tipo DESC, anio;
