# Resultados de `sql/ex8_tres_anios.sql`

Generado con `python scripts/run_sql.py sql/ex8_tres_anios.sql` el 2026-10-08 20:55 (DuckDB 1.5.5).

## Q8.1 Archivos y registros por tipo y anio

```sql
SELECT
    split_part(replace(file_name, '\', '/'), '/', 3) AS tipo,
    split_part(replace(file_name, '\', '/'), '/', 4) AS anio,
    count(*)                                         AS archivos,
    sum(num_rows)                                    AS registros
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo DESC, anio;
```

Tiempo: 0.29 s

| tipo | anio | archivos | registros |
|---|---|---|---|
| yellow | 2024 | 12 | 41169720 |
| yellow | 2025 | 12 | 48722602 |
| yellow | 2026 | 8 | 29703355 |
| green | 2024 | 12 | 660218 |
| green | 2025 | 12 | 591375 |
| green | 2026 | 8 | 337114 |

## Q8.2 Resumen por anio y tipo (enero-agosto, viajes validos)

```sql
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
```

Tiempo: 53.65 s

| tipo | anio | viajes_por_dia | total_promedio | tarifa_mediana | velocidad_mediana | pct_tarjeta | pct_sin_info_pago | pct_con_cuota_cbd |
|---|---|---|---|---|---|---|---|---|
| yellow | 2024 | 104,187 | 28.29 | 13.5 | 9.5 | 76 | 9 | 0 |
| yellow | 2025 | 117,700 | 28.29 | 14.2 | 9.7 | 68.8 | 19.7 | 73.1 |
| yellow | 2026 | 115,837 | 30.18 | 15.6 | 9.3 | 65.4 | 25 | 72.5 |
| green | 2024 | 1,691 | 23.77 | 13.5 | 10.4 | 67.9 | 4.1 | 0 |
| green | 2025 | 1,522 | 24.82 | 13.5 | 10.3 | 69.9 | 6.7 | 9.9 |
| green | 2026 | 1,315 | 25.38 | 13.5 | 10 | 65.6 | 14.9 | 8.6 |

## Q8.3 Cuota de congestion CBD por mes (amarillos)

```sql
SELECT
    mes_archivo                                                                 AS mes,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee > 0) / count(*), 1) AS pct_con_cuota,
    round(avg(cbd_congestion_fee), 2)                                           AS cuota_promedio
FROM viajes_validos
WHERE tipo = 'yellow' AND anio >= 2025
GROUP BY mes
ORDER BY mes;
```

Tiempo: 28.56 s

| mes | pct_con_cuota | cuota_promedio |
|---|---|---|
| 2025-01 | 65.9 | 0.49 |
| 2025-02 | 74.1 | 0.56 |
| 2025-03 | 74.4 | 0.56 |
| 2025-04 | 74.1 | 0.56 |
| 2025-05 | 73.4 | 0.55 |
| 2025-06 | 73.8 | 0.55 |
| 2025-07 | 74.5 | 0.56 |
| 2025-08 | 73.8 | 0.55 |
| 2025-09 | 74 | 0.56 |
| 2025-10 | 73.7 | 0.55 |
| 2025-11 | 73 | 0.55 |
| 2025-12 | 72.2 | 0.54 |
| 2026-01 | 71 | 0.53 |
| 2026-02 | 71 | 0.53 |
| 2026-03 | 71.6 | 0.54 |
| 2026-04 | 71.8 | 0.54 |
| 2026-05 | 66.8 | 0.5 |
| 2026-06 | 74.4 | 0.56 |
| 2026-07 | 77.3 | 0.58 |
| 2026-08 | 77.3 | 0.58 |

## Q8.4 Registros excluidos por motivo y anio (% de los registros del anio)

```sql
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
```

Tiempo: 29.11 s

| motivo | pct_2024 | pct_2025 | pct_2026 |
|---|---|---|---|
| monto negativo | 1.54 | 5.21 | 0.46 |
| distancia = 0 | 1.09 | 2.09 | 2.44 |
| duracion < 1 min | 1.21 | 1.15 | 1.07 |
| duracion <= 0 | 0.03 | 1.11 | 1.24 |
| duracion > 6 h | 0.06 | 0.04 | 0.03 |
| distancia > 100 mi | 0 | 0.01 | 0 |
| total >= 1000 | 0 | 0 | 0 |
| fecha fuera del mes del archivo | 0 | 0 | 0 |
