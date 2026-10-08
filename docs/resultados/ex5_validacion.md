# Resultados de `sql/ex5_validacion.sql`

Generado con `python scripts/run_sql.py sql/ex5_validacion.sql` el 2026-10-08 19:03 (DuckDB 1.5.5).

## Q5.1 Archivos y registros por tipo y anio (metadatos Parquet)

```sql
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    split_part(replace(file_name, '\', '/'), '/', 4) AS anio,
    count(*)                                         AS archivos,
    sum(num_rows)                                    AS registros,
    round(sum(file_size_bytes) / 1024 / 1024, 1)     AS mib
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo DESC, anio;
```

Tiempo: 0.07 s

| tipo | anio | archivos | registros | mib |
|---|---|---|---|---|
| yellow | 2024 | 12 | 41169720 | 660.9 |
| yellow | 2026 | 8 | 29703355 | 487.8 |
| green | 2024 | 12 | 660218 | 15.2 |
| green | 2026 | 8 | 337114 | 7.9 |

## Q5.2 Meses esperados vs. meses presentes por tipo y anio

```sql
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
```

Tiempo: 0.07 s

| tipo | anio | meses_esperados | meses_presentes | meses_faltantes | archivos_vacios |
|---|---|---|---|---|---|
| yellow | 2024 | 12 | 12 | - | 0 |
| yellow | 2026 | 8 | 8 | - | 0 |
| green | 2024 | 12 | 12 | - | 0 |
| green | 2026 | 8 | 8 | - | 0 |

## Q5.3 Registros por mes: metadatos vs. lectura de datos (ambos anios)

```sql
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
```

Tiempo: 0.22 s

| tipo | mes | filas_metadatos | filas_leidas | diferencia |
|---|---|---|---|---|
| yellow | 2024-01 | 2964624 | 2964624 | 0 |
| yellow | 2024-02 | 3007526 | 3007526 | 0 |
| yellow | 2024-03 | 3582628 | 3582628 | 0 |
| yellow | 2024-04 | 3514289 | 3514289 | 0 |
| yellow | 2024-05 | 3723833 | 3723833 | 0 |
| yellow | 2024-06 | 3539193 | 3539193 | 0 |
| yellow | 2024-07 | 3076903 | 3076903 | 0 |
| yellow | 2024-08 | 2979183 | 2979183 | 0 |
| yellow | 2024-09 | 3633030 | 3633030 | 0 |
| yellow | 2024-10 | 3833771 | 3833771 | 0 |
| yellow | 2024-11 | 3646369 | 3646369 | 0 |
| yellow | 2024-12 | 3668371 | 3668371 | 0 |
| yellow | 2026-01 | 3724889 | 3724889 | 0 |
| yellow | 2026-02 | 3399866 | 3399866 | 0 |
| yellow | 2026-03 | 3952451 | 3952451 | 0 |
| yellow | 2026-04 | 3831240 | 3831240 | 0 |
| yellow | 2026-05 | 4090836 | 4090836 | 0 |
| yellow | 2026-06 | 3837248 | 3837248 | 0 |
| yellow | 2026-07 | 3530109 | 3530109 | 0 |
| yellow | 2026-08 | 3336716 | 3336716 | 0 |
| green | 2024-01 | 56551 | 56551 | 0 |
| green | 2024-02 | 53577 | 53577 | 0 |
| green | 2024-03 | 57457 | 57457 | 0 |
| green | 2024-04 | 56471 | 56471 | 0 |
| green | 2024-05 | 61003 | 61003 | 0 |
| green | 2024-06 | 54748 | 54748 | 0 |
| green | 2024-07 | 51837 | 51837 | 0 |
| green | 2024-08 | 51771 | 51771 | 0 |
| green | 2024-09 | 54440 | 54440 | 0 |
| green | 2024-10 | 56147 | 56147 | 0 |
| green | 2024-11 | 52222 | 52222 | 0 |
| green | 2024-12 | 53994 | 53994 | 0 |
| green | 2026-01 | 40272 | 40272 | 0 |
| green | 2026-02 | 37373 | 37373 | 0 |
| green | 2026-03 | 44208 | 44208 | 0 |
| green | 2026-04 | 44238 | 44238 | 0 |
| green | 2026-05 | 44921 | 44921 | 0 |
| green | 2026-06 | 44163 | 44163 | 0 |
| green | 2026-07 | 41252 | 41252 | 0 |
| green | 2026-08 | 40687 | 40687 | 0 |

## Q5.4 Columnas que no estan presentes en todos los archivos del tipo

```sql
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
```

Tiempo: 0.07 s

| tipo | columna | anios_con_columna | archivos_con_columna | archivos_del_tipo | tipos_fisicos |
|---|---|---|---|---|---|
| yellow | cbd_congestion_fee | 2026 | 8 | 20 | DOUBLE |
| yellow | request_source | 2026 | 3 | 20 | BYTE_ARRAY |
| green | cbd_congestion_fee | 2026 | 8 | 20 | DOUBLE |
| green | request_source | 2026 | 3 | 20 | BYTE_ARRAY |

## Q5.5 Consulta conjunta 2024 vs 2026 (enero-agosto, viajes validos)

```sql
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
```

Tiempo: 9.71 s

| tipo | anio | viajes | viajes_por_dia | ingresos_musd | total_promedio | tarifa_mediana | distancia_mediana | velocidad_mediana | pct_tarjeta | pct_sin_info_pago | pct_con_cuota_cbd |
|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2024 | 25421626 | 104,187 | 719.1 | 28.29 | 13.5 | 1.8 | 9.5 | 76 | 9 | 0 |
| yellow | 2026 | 28148358 | 115,837 | 849.4 | 30.18 | 15.6 | 1.94 | 9.3 | 65.4 | 25 | 72.5 |
| green | 2024 | 412671 | 1,691 | 9.8 | 23.77 | 13.5 | 1.98 | 10.4 | 67.9 | 4.1 | 0 |
| green | 2026 | 319609 | 1,315 | 8.1 | 25.38 | 13.5 | 2.17 | 10 | 65.6 | 14.9 | 8.6 |

## Q5.6 Variacion 2026 vs 2024 (enero-agosto)

```sql
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
```

Tiempo: 7.74 s

| tipo | var_pct_viajes_por_dia | var_pct_total_promedio | var_pct_tarifa_mediana | var_pct_velocidad_mediana |
|---|---|---|---|---|
| yellow | 11.2 | 6.7 | 15.6 | -2.5 |
| green | -22.2 | 6.8 | 0 | -3.2 |

## Q5.7 Calidad de datos por anio (proporcion de registros excluidos y sin informacion de pago)

```sql
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
```

Tiempo: 4.94 s

| tipo | anio | registros | pct_excluidos | pct_distancia_cero | pct_monto_negativo | pct_sin_metadatos |
|---|---|---|---|---|---|---|
| yellow | 2024 | 41169720 | 3.9 | 1.05 | 1.57 | 9.94 |
| yellow | 2026 | 29703355 | 5.24 | 2.45 | 0.46 | 25.98 |
| green | 2024 | 660218 | 6.91 | 3.21 | 0.12 | 3.68 |
| green | 2026 | 337114 | 5.19 | 1.37 | 0.1 | 14.47 |
