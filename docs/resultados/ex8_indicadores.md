# Resultados de `sql/ex7_indicadores.sql`

Generado con `python scripts/run_sql.py sql/ex7_indicadores.sql` el 2026-10-08 20:54 (DuckDB 1.5.5).

## I1 Viajes por dia segun mes y tipo

```sql
SELECT date_trunc('month', pickup)::DATE           AS mes,
       tipo,
       round(count(*) / count(DISTINCT pickup::DATE)) AS viajes_por_dia
FROM viajes_validos
GROUP BY ALL
ORDER BY mes, tipo;
```

Tiempo: 9.10 s

| mes | tipo | viajes_por_dia |
|---|---|---|
| 2024-01-01 | green | 1,702 |
| 2024-01-01 | yellow | 92,240 |
| 2024-02-01 | green | 1,721 |
| 2024-02-01 | yellow | 99,710 |
| 2024-03-01 | green | 1,729 |
| 2024-03-01 | yellow | 110,590 |
| 2024-04-01 | green | 1,746 |
| 2024-04-01 | yellow | 113,422 |
| 2024-05-01 | green | 1,834 |
| 2024-05-01 | yellow | 116,305 |
| 2024-06-01 | green | 1,704 |
| 2024-06-01 | yellow | 113,874 |
| 2024-07-01 | green | 1,548 |
| 2024-07-01 | yellow | 95,558 |
| 2024-08-01 | green | 1,550 |
| 2024-08-01 | yellow | 92,118 |
| 2024-09-01 | green | 1,689 |
| 2024-09-01 | yellow | 115,711 |
| 2024-10-01 | green | 1,697 |
| 2024-10-01 | yellow | 118,358 |
| 2024-11-01 | green | 1,620 |
| 2024-11-01 | yellow | 116,586 |
| 2024-12-01 | green | 1,615 |
| 2024-12-01 | yellow | 113,093 |
| 2025-01-01 | green | 1,444 |
| 2025-01-01 | yellow | 104,590 |
| 2025-02-01 | green | 1,536 |
| 2025-02-01 | yellow | 117,739 |
| 2025-03-01 | green | 1,524 |
| 2025-03-01 | yellow | 123,060 |
| 2025-04-01 | green | 1,591 |
| 2025-04-01 | yellow | 121,995 |
| 2025-05-01 | green | 1,648 |
| 2025-05-01 | yellow | 131,575 |
| 2025-06-01 | green | 1,540 |
| 2025-06-01 | yellow | 128,549 |
| 2025-07-01 | green | 1,479 |
| 2025-07-01 | yellow | 112,357 |
| 2025-08-01 | green | 1,417 |
| 2025-08-01 | yellow | 102,225 |
| 2025-09-01 | green | 1,555 |
| 2025-09-01 | yellow | 127,499 |
| 2025-10-01 | green | 1,517 |
| 2025-10-01 | yellow | 126,796 |
| 2025-11-01 | green | 1,487 |
| 2025-11-01 | yellow | 121,054 |
| 2025-12-01 | green | 1,478 |
| 2025-12-01 | yellow | 130,213 |
| 2026-01-01 | green | 1,236 |
| 2026-01-01 | yellow | 113,100 |
| 2026-02-01 | green | 1,264 |
| 2026-02-01 | yellow | 114,337 |
| 2026-03-01 | green | 1,357 |
| 2026-03-01 | yellow | 121,025 |
| 2026-04-01 | green | 1,398 |
| 2026-04-01 | yellow | 122,128 |
| 2026-05-01 | green | 1,376 |
| 2026-05-01 | yellow | 125,837 |
| 2026-06-01 | green | 1,400 |
| 2026-06-01 | yellow | 121,161 |

_(4 filas adicionales omitidas)_

## I2 Viajes por hora del dia (% del total de cada tipo)

```sql
SELECT hour(pickup) AS hora,
       tipo,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo), 2) AS pct_viajes
FROM viajes_validos
GROUP BY hora, tipo
ORDER BY hora, tipo;
```

Tiempo: 2.61 s

| hora | tipo | pct_viajes |
|---|---|---|
| 0 | green | 1.61 |
| 0 | yellow | 3.06 |
| 1 | green | 1.06 |
| 1 | yellow | 2 |
| 2 | green | 0.74 |
| 2 | yellow | 1.31 |
| 3 | green | 0.57 |
| 3 | yellow | 0.89 |
| 4 | green | 0.51 |
| 4 | yellow | 0.7 |
| 5 | green | 0.62 |
| 5 | yellow | 0.76 |
| 6 | green | 1.74 |
| 6 | yellow | 1.55 |
| 7 | green | 3.87 |
| 7 | yellow | 2.88 |
| 8 | green | 4.98 |
| 8 | yellow | 3.92 |
| 9 | green | 5.34 |
| 9 | yellow | 4.21 |
| 10 | green | 5.27 |
| 10 | yellow | 4.41 |
| 11 | green | 5.26 |
| 11 | yellow | 4.76 |
| 12 | green | 5.6 |
| 12 | yellow | 5.18 |
| 13 | green | 5.64 |
| 13 | yellow | 5.41 |
| 14 | green | 6.38 |
| 14 | yellow | 5.82 |
| 15 | green | 6.96 |
| 15 | yellow | 6.02 |
| 16 | green | 7.58 |
| 16 | yellow | 5.93 |
| 17 | green | 8.1 |
| 17 | yellow | 6.53 |
| 18 | green | 7.7 |
| 18 | yellow | 6.81 |
| 19 | green | 5.99 |
| 19 | yellow | 6.11 |
| 20 | green | 4.59 |
| 20 | yellow | 5.83 |
| 21 | green | 3.99 |
| 21 | yellow | 5.99 |
| 22 | green | 3.35 |
| 22 | yellow | 5.56 |
| 23 | green | 2.54 |
| 23 | yellow | 4.35 |

## I3 Viajes por dia de la semana (% sobre el promedio del tipo)

```sql
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
```

Tiempo: 2.52 s

| dia | tipo | pct_vs_promedio |
|---|---|---|
| 1 Monday | green | -0.4 |
| 1 Monday | yellow | -15 |
| 2 Tuesday | green | 5.7 |
| 2 Tuesday | yellow | -1.9 |
| 3 Wednesday | green | 9.9 |
| 3 Wednesday | yellow | 3.9 |
| 4 Thursday | green | 12.5 |
| 4 Thursday | yellow | 8.8 |
| 5 Friday | green | 5.2 |
| 5 Friday | yellow | 3.7 |
| 6 Saturday | green | -13.3 |
| 6 Saturday | yellow | 8.5 |
| 7 Sunday | green | -19.6 |
| 7 Sunday | yellow | -8 |

## I4 Tarifa mediana y total promedio por mes (amarillos)

```sql
SELECT date_trunc('month', pickup)::DATE AS mes,
       median(fare_amount)                AS tarifa_mediana,
       round(avg(total_amount), 2)        AS total_promedio
FROM viajes_validos
WHERE tipo = 'yellow'
GROUP BY mes
ORDER BY mes;
```

Tiempo: 9.45 s

| mes | tarifa_mediana | total_promedio |
|---|---|---|
| 2024-01-01 | 12.8 | 27.3 |
| 2024-02-01 | 12.8 | 27.2 |
| 2024-03-01 | 13.5 | 27.82 |
| 2024-04-01 | 13.83 | 28.15 |
| 2024-05-01 | 14.2 | 28.95 |
| 2024-06-01 | 14.2 | 28.65 |
| 2024-07-01 | 14.2 | 28.93 |
| 2024-08-01 | 14.2 | 29.17 |
| 2024-09-01 | 14.9 | 29.44 |
| 2024-10-01 | 14.2 | 29.33 |
| 2024-11-01 | 14.2 | 28.43 |
| 2024-12-01 | 14.2 | 29.33 |
| 2025-01-01 | 12.8 | 26.78 |
| 2025-02-01 | 13.5 | 26.57 |
| 2025-03-01 | 13.89 | 27.89 |
| 2025-04-01 | 14.2 | 28.23 |
| 2025-05-01 | 14.9 | 29.22 |
| 2025-06-01 | 14.9 | 29.4 |
| 2025-07-01 | 14.9 | 28.98 |
| 2025-08-01 | 14.2 | 28.88 |
| 2025-09-01 | 15.6 | 29.68 |
| 2025-10-01 | 14.9 | 29.31 |
| 2025-11-01 | 14.2 | 28.39 |
| 2025-12-01 | 16.99 | 31.32 |
| 2026-01-01 | 15.6 | 29.61 |
| 2026-02-01 | 16.3 | 30.4 |
| 2026-03-01 | 15.6 | 30.21 |
| 2026-04-01 | 15.6 | 30.03 |
| 2026-05-01 | 16.3 | 30.48 |
| 2026-06-01 | 15.6 | 30.52 |
| 2026-07-01 | 15.6 | 30.06 |
| 2026-08-01 | 15.6 | 30.07 |

## I5 Forma de pago por anio y tipo (% de viajes)

```sql
SELECT anio || ' ' || tipo AS grupo,
       CASE coalesce(payment_type, 0)
           WHEN 0 THEN 'sin informacion' WHEN 1 THEN 'tarjeta'
           WHEN 2 THEN 'efectivo' ELSE 'otro'
       END                 AS forma_pago,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY anio, tipo), 1) AS pct_viajes
FROM viajes_validos
GROUP BY anio, tipo, forma_pago
ORDER BY grupo, forma_pago;
```

Tiempo: 3.72 s

| grupo | forma_pago | pct_viajes |
|---|---|---|
| 2024 green | efectivo | 27 |
| 2024 green | otro | 0.3 |
| 2024 green | sin informacion | 3.8 |
| 2024 green | tarjeta | 68.9 |
| 2024 yellow | efectivo | 13.2 |
| 2024 yellow | otro | 1.3 |
| 2024 yellow | sin informacion | 9.3 |
| 2024 yellow | tarjeta | 76.1 |
| 2025 green | efectivo | 22.2 |
| 2025 green | otro | 0.3 |
| 2025 green | sin informacion | 8.3 |
| 2025 green | tarjeta | 69.2 |
| 2025 yellow | efectivo | 9.7 |
| 2025 yellow | otro | 1.5 |
| 2025 yellow | sin informacion | 20.1 |
| 2025 yellow | tarjeta | 68.7 |
| 2026 green | efectivo | 19.3 |
| 2026 green | otro | 0.2 |
| 2026 green | sin informacion | 14.9 |
| 2026 green | tarjeta | 65.6 |
| 2026 yellow | efectivo | 9 |
| 2026 yellow | otro | 0.6 |
| 2026 yellow | sin informacion | 25 |
| 2026 yellow | tarjeta | 65.4 |

## I6 Propina con tarjeta como % de la tarifa por mes y tipo

```sql
SELECT date_trunc('month', pickup)::DATE                  AS mes,
       tipo,
       round(100.0 * sum(tip_amount) / sum(fare_amount), 1) AS propina_pct_tarifa
FROM viajes_validos
WHERE payment_type = 1 AND fare_amount > 0
GROUP BY ALL
ORDER BY mes, tipo;
```

Tiempo: 3.97 s

| mes | tipo | propina_pct_tarifa |
|---|---|---|
| 2024-01-01 | green | 21.3 |
| 2024-01-01 | yellow | 22.6 |
| 2024-02-01 | green | 21 |
| 2024-02-01 | yellow | 22.6 |
| 2024-03-01 | green | 21 |
| 2024-03-01 | yellow | 22.4 |
| 2024-04-01 | green | 21.1 |
| 2024-04-01 | yellow | 22.3 |
| 2024-05-01 | green | 20.7 |
| 2024-05-01 | yellow | 22.2 |
| 2024-06-01 | green | 20.4 |
| 2024-06-01 | yellow | 22 |
| 2024-07-01 | green | 20.6 |
| 2024-07-01 | yellow | 21.6 |
| 2024-08-01 | green | 20.1 |
| 2024-08-01 | yellow | 21.4 |
| 2024-09-01 | green | 19.9 |
| 2024-09-01 | yellow | 21.7 |
| 2024-10-01 | green | 20.6 |
| 2024-10-01 | yellow | 22 |
| 2024-11-01 | green | 20.7 |
| 2024-11-01 | yellow | 22 |
| 2024-12-01 | green | 21 |
| 2024-12-01 | yellow | 22.2 |
| 2025-01-01 | green | 21.4 |
| 2025-01-01 | yellow | 23 |
| 2025-02-01 | green | 21.1 |
| 2025-02-01 | yellow | 22.9 |
| 2025-03-01 | green | 20.7 |
| 2025-03-01 | yellow | 22.7 |
| 2025-04-01 | green | 20.8 |
| 2025-04-01 | yellow | 22.6 |
| 2025-05-01 | green | 20.6 |
| 2025-05-01 | yellow | 22.2 |
| 2025-06-01 | green | 20.4 |
| 2025-06-01 | yellow | 22.2 |
| 2025-07-01 | green | 20.4 |
| 2025-07-01 | yellow | 21.7 |
| 2025-08-01 | green | 19.3 |
| 2025-08-01 | yellow | 21.3 |
| 2025-09-01 | green | 19.9 |
| 2025-09-01 | yellow | 21.4 |
| 2025-10-01 | green | 20.8 |
| 2025-10-01 | yellow | 21.5 |
| 2025-11-01 | green | 20.9 |
| 2025-11-01 | yellow | 21.3 |
| 2025-12-01 | green | 21.5 |
| 2025-12-01 | yellow | 21.3 |
| 2026-01-01 | green | 21.6 |
| 2026-01-01 | yellow | 21.2 |
| 2026-02-01 | green | 21.6 |
| 2026-02-01 | yellow | 21.2 |
| 2026-03-01 | green | 21.6 |
| 2026-03-01 | yellow | 21.1 |
| 2026-04-01 | green | 21.5 |
| 2026-04-01 | yellow | 21.1 |
| 2026-05-01 | green | 20.9 |
| 2026-05-01 | yellow | 21.1 |
| 2026-06-01 | green | 20.8 |
| 2026-06-01 | yellow | 23.1 |

_(4 filas adicionales omitidas)_

## I7 Borough de origen por anio (% de viajes del anio)

```sql
SELECT coalesce(z.Borough, 'Sin zona') AS borough,
       anio::VARCHAR                   AS anio,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY anio), 2) AS pct_viajes
FROM viajes_validos v
LEFT JOIN zonas z ON z.LocationID = v.PULocationID
GROUP BY z.Borough, v.anio
ORDER BY borough, anio;
```

Tiempo: 2.96 s

| borough | anio | pct_viajes |
|---|---|---|
| Bronx | 2024 | 0.3 |
| Bronx | 2025 | 0.78 |
| Bronx | 2026 | 0.79 |
| Brooklyn | 2024 | 1.58 |
| Brooklyn | 2025 | 3.47 |
| Brooklyn | 2026 | 3.74 |
| EWR | 2024 | 0 |
| EWR | 2025 | 0 |
| EWR | 2026 | 0 |
| Manhattan | 2024 | 88.47 |
| Manhattan | 2025 | 86.04 |
| Manhattan | 2026 | 86.44 |
| N/A | 2024 | 0.02 |
| N/A | 2025 | 0.01 |
| N/A | 2026 | 0.02 |
| Queens | 2024 | 9.36 |
| Queens | 2025 | 9.52 |
| Queens | 2026 | 8.9 |
| Staten Island | 2024 | 0 |
| Staten Island | 2025 | 0.01 |
| Staten Island | 2026 | 0.01 |
| Unknown | 2024 | 0.28 |
| Unknown | 2025 | 0.17 |
| Unknown | 2026 | 0.1 |

## I8 Velocidad mediana por hora del dia y anio (amarillos)

```sql
SELECT hour(pickup)               AS hora,
       anio::VARCHAR              AS anio,
       round(median(velocidad_mph), 1) AS velocidad_mediana_mph
FROM viajes_validos
WHERE tipo = 'yellow'
GROUP BY ALL
ORDER BY hora, anio;
```

Tiempo: 10.56 s

| hora | anio | velocidad_mediana_mph |
|---|---|---|
| 0 | 2024 | 11.8 |
| 0 | 2025 | 12.1 |
| 0 | 2026 | 11.8 |
| 1 | 2024 | 12.1 |
| 1 | 2025 | 12.4 |
| 1 | 2026 | 12.3 |
| 2 | 2024 | 12.6 |
| 2 | 2025 | 12.9 |
| 2 | 2026 | 12.9 |
| 3 | 2024 | 13.6 |
| 3 | 2025 | 13.9 |
| 3 | 2026 | 13.8 |
| 4 | 2024 | 15.5 |
| 4 | 2025 | 15.6 |
| 4 | 2026 | 15.4 |
| 5 | 2024 | 16.5 |
| 5 | 2025 | 16.4 |
| 5 | 2026 | 16 |
| 6 | 2024 | 14 |
| 6 | 2025 | 14.1 |
| 6 | 2026 | 13.8 |
| 7 | 2024 | 11.2 |
| 7 | 2025 | 11.3 |
| 7 | 2026 | 11.1 |
| 8 | 2024 | 9.3 |
| 8 | 2025 | 9.4 |
| 8 | 2026 | 9.3 |
| 9 | 2024 | 8.9 |
| 9 | 2025 | 9.1 |
| 9 | 2026 | 8.9 |
| 10 | 2024 | 8.7 |
| 10 | 2025 | 8.8 |
| 10 | 2026 | 8.6 |
| 11 | 2024 | 8.2 |
| 11 | 2025 | 8.3 |
| 11 | 2026 | 8.1 |
| 12 | 2024 | 8.2 |
| 12 | 2025 | 8.3 |
| 12 | 2026 | 8.1 |
| 13 | 2024 | 8.2 |
| 13 | 2025 | 8.3 |
| 13 | 2026 | 8.1 |
| 14 | 2024 | 8.1 |
| 14 | 2025 | 8.2 |
| 14 | 2026 | 8 |
| 15 | 2024 | 8 |
| 15 | 2025 | 8 |
| 15 | 2026 | 7.9 |
| 16 | 2024 | 8.2 |
| 16 | 2025 | 8.2 |
| 16 | 2026 | 8 |
| 17 | 2024 | 8.2 |
| 17 | 2025 | 8.2 |
| 17 | 2026 | 8 |
| 18 | 2024 | 8.5 |
| 18 | 2025 | 8.5 |
| 18 | 2026 | 8.3 |
| 19 | 2024 | 9.2 |
| 19 | 2025 | 9.1 |
| 19 | 2026 | 8.9 |

_(12 filas adicionales omitidas)_

## I9 Peso de los viajes de aeropuerto por anio (amarillos)

```sql
SELECT anio::VARCHAR AS anio,
       round(100.0 * count(*) FILTER (WHERE PULocationID IN (1, 132, 138) OR DOLocationID IN (1, 132, 138))
             / count(*), 1)                                        AS pct_viajes,
       round(100.0 * sum(total_amount) FILTER (WHERE PULocationID IN (1, 132, 138) OR DOLocationID IN (1, 132, 138))
             / sum(total_amount), 1)                               AS pct_ingresos
FROM viajes_validos
WHERE tipo = 'yellow'
GROUP BY anio
ORDER BY anio;
```

Tiempo: 2.80 s

| anio | pct_viajes | pct_ingresos |
|---|---|---|
| 2024 | 10.1 | 27.8 |
| 2025 | 8.8 | 24.1 |
| 2026 | 8.1 | 20.9 |

## I10 Calidad de datos por mes (% de registros)

```sql
SELECT strptime(mes_archivo, '%Y-%m')::DATE                                     AS mes,
       round(100.0 * count(*) FILTER (WHERE motivo_exclusion IS NOT NULL) / count(*), 2) AS pct_excluidos,
       round(100.0 * count(*) FILTER (WHERE coalesce(payment_type, 0) = 0) / count(*), 2) AS pct_sin_info_pago
FROM viajes
GROUP BY mes
ORDER BY mes;
```

Tiempo: 5.38 s

| mes | pct_excluidos | pct_sin_info_pago |
|---|---|---|
| 2024-01-01 | 3.61 | 4.75 |
| 2024-02-01 | 3.91 | 6.16 |
| 2024-03-01 | 4.35 | 11.77 |
| 2024-04-01 | 3.24 | 11.5 |
| 2024-05-01 | 3.24 | 10.74 |
| 2024-06-01 | 3.52 | 11.48 |
| 2024-07-01 | 3.79 | 8.97 |
| 2024-08-01 | 4.2 | 8.59 |
| 2024-09-01 | 4.49 | 13.16 |
| 2024-10-01 | 4.32 | 10.17 |
| 2024-11-01 | 4.12 | 10.15 |
| 2024-12-01 | 4.47 | 8.82 |
| 2025-01-01 | 6.71 | 15.38 |
| 2025-02-01 | 7.85 | 22.33 |
| 2025-03-01 | 7.98 | 21.93 |
| 2025-04-01 | 7.83 | 18.62 |
| 2025-05-01 | 11.13 | 25.81 |
| 2025-06-01 | 10.74 | 27.83 |
| 2025-07-01 | 10.6 | 26.45 |
| 2025-08-01 | 11.26 | 24.61 |
| 2025-09-01 | 9.96 | 24.94 |
| 2025-10-01 | 11.17 | 22.24 |
| 2025-11-01 | 13.06 | 24.13 |
| 2025-12-01 | 6.22 | 27.6 |
| 2026-01-01 | 5.86 | 29.04 |
| 2026-02-01 | 5.83 | 29.93 |
| 2026-03-01 | 5.07 | 23.83 |
| 2026-04-01 | 4.38 | 20.8 |
| 2026-05-01 | 4.65 | 23.24 |
| 2026-06-01 | 5.27 | 26.28 |
| 2026-07-01 | 5.51 | 27.33 |
| 2026-08-01 | 5.49 | 27.46 |
