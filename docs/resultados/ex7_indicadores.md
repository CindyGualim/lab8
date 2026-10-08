# Resultados de `sql/ex7_indicadores.sql`

Generado con `python scripts/run_sql.py sql/ex7_indicadores.sql` el 2026-10-08 19:34 (DuckDB 1.5.5).

## I1 Viajes por dia segun mes y tipo

```sql
SELECT date_trunc('month', pickup)::DATE           AS mes,
       tipo,
       round(count(*) / count(DISTINCT pickup::DATE)) AS viajes_por_dia
FROM viajes_validos
GROUP BY ALL
ORDER BY mes, tipo;
```

Tiempo: 4.34 s

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
| 2026-07-01 | green | 1,256 |
| 2026-07-01 | yellow | 107,603 |
| 2026-08-01 | green | 1,236 |
| 2026-08-01 | yellow | 101,734 |

## I2 Viajes por hora del dia (% del total de cada tipo)

```sql
SELECT hour(pickup) AS hora,
       tipo,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo), 2) AS pct_viajes
FROM viajes_validos
GROUP BY hora, tipo
ORDER BY hora, tipo;
```

Tiempo: 1.62 s

| hora | tipo | pct_viajes |
|---|---|---|
| 0 | green | 1.66 |
| 0 | yellow | 3.02 |
| 1 | green | 1.1 |
| 1 | yellow | 1.97 |
| 2 | green | 0.78 |
| 2 | yellow | 1.29 |
| 3 | green | 0.59 |
| 3 | yellow | 0.88 |
| 4 | green | 0.52 |
| 4 | yellow | 0.68 |
| 5 | green | 0.6 |
| 5 | yellow | 0.75 |
| 6 | green | 1.69 |
| 6 | yellow | 1.55 |
| 7 | green | 3.83 |
| 7 | yellow | 2.88 |
| 8 | green | 4.91 |
| 8 | yellow | 3.93 |
| 9 | green | 5.33 |
| 9 | yellow | 4.22 |
| 10 | green | 5.25 |
| 10 | yellow | 4.42 |
| 11 | green | 5.25 |
| 11 | yellow | 4.79 |
| 12 | green | 5.56 |
| 12 | yellow | 5.21 |
| 13 | green | 5.59 |
| 13 | yellow | 5.43 |
| 14 | green | 6.41 |
| 14 | yellow | 5.85 |
| 15 | green | 6.99 |
| 15 | yellow | 6.04 |
| 16 | green | 7.57 |
| 16 | yellow | 5.97 |
| 17 | green | 8.11 |
| 17 | yellow | 6.56 |
| 18 | green | 7.73 |
| 18 | yellow | 6.86 |
| 19 | green | 6 |
| 19 | yellow | 6.12 |
| 20 | green | 4.6 |
| 20 | yellow | 5.8 |
| 21 | green | 4.03 |
| 21 | yellow | 5.96 |
| 22 | green | 3.35 |
| 22 | yellow | 5.52 |
| 23 | green | 2.55 |
| 23 | yellow | 4.32 |

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

Tiempo: 1.26 s

| dia | tipo | pct_vs_promedio |
|---|---|---|
| 1 Monday | green | -1.4 |
| 1 Monday | yellow | -15.6 |
| 2 Tuesday | green | 5.4 |
| 2 Tuesday | yellow | -1.6 |
| 3 Wednesday | green | 10.1 |
| 3 Wednesday | yellow | 4.4 |
| 4 Thursday | green | 13 |
| 4 Thursday | yellow | 9.8 |
| 5 Friday | green | 5.5 |
| 5 Friday | yellow | 3.9 |
| 6 Saturday | green | -12.6 |
| 6 Saturday | yellow | 8.3 |
| 7 Sunday | green | -20.1 |
| 7 Sunday | yellow | -9.2 |

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

Tiempo: 5.50 s

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

Tiempo: 1.89 s

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

Tiempo: 2.21 s

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
| 2026-07-01 | green | 20.5 |
| 2026-07-01 | yellow | 22.4 |
| 2026-08-01 | green | 20.5 |
| 2026-08-01 | yellow | 22.1 |

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

Tiempo: 1.42 s

| borough | anio | pct_viajes |
|---|---|---|
| Bronx | 2024 | 0.3 |
| Bronx | 2026 | 0.79 |
| Brooklyn | 2024 | 1.58 |
| Brooklyn | 2026 | 3.74 |
| EWR | 2024 | 0 |
| EWR | 2026 | 0 |
| Manhattan | 2024 | 88.47 |
| Manhattan | 2026 | 86.44 |
| N/A | 2024 | 0.02 |
| N/A | 2026 | 0.02 |
| Queens | 2024 | 9.36 |
| Queens | 2026 | 8.9 |
| Staten Island | 2024 | 0 |
| Staten Island | 2026 | 0.01 |
| Unknown | 2024 | 0.28 |
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

Tiempo: 5.46 s

| hora | anio | velocidad_mediana_mph |
|---|---|---|
| 0 | 2024 | 11.8 |
| 0 | 2026 | 11.8 |
| 1 | 2024 | 12.1 |
| 1 | 2026 | 12.3 |
| 2 | 2024 | 12.6 |
| 2 | 2026 | 12.9 |
| 3 | 2024 | 13.6 |
| 3 | 2026 | 13.8 |
| 4 | 2024 | 15.5 |
| 4 | 2026 | 15.4 |
| 5 | 2024 | 16.5 |
| 5 | 2026 | 16 |
| 6 | 2024 | 14 |
| 6 | 2026 | 13.8 |
| 7 | 2024 | 11.2 |
| 7 | 2026 | 11.1 |
| 8 | 2024 | 9.3 |
| 8 | 2026 | 9.3 |
| 9 | 2024 | 8.9 |
| 9 | 2026 | 8.9 |
| 10 | 2024 | 8.7 |
| 10 | 2026 | 8.6 |
| 11 | 2024 | 8.2 |
| 11 | 2026 | 8.1 |
| 12 | 2024 | 8.2 |
| 12 | 2026 | 8.1 |
| 13 | 2024 | 8.2 |
| 13 | 2026 | 8.1 |
| 14 | 2024 | 8.1 |
| 14 | 2026 | 8 |
| 15 | 2024 | 8 |
| 15 | 2026 | 7.9 |
| 16 | 2024 | 8.2 |
| 16 | 2026 | 8 |
| 17 | 2024 | 8.2 |
| 17 | 2026 | 8 |
| 18 | 2024 | 8.5 |
| 18 | 2026 | 8.3 |
| 19 | 2024 | 9.2 |
| 19 | 2026 | 8.9 |
| 20 | 2024 | 9.9 |
| 20 | 2026 | 9.8 |
| 21 | 2024 | 10.3 |
| 21 | 2026 | 10.1 |
| 22 | 2024 | 10.7 |
| 22 | 2026 | 10.5 |
| 23 | 2024 | 11.3 |
| 23 | 2026 | 11.2 |

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

Tiempo: 1.56 s

| anio | pct_viajes | pct_ingresos |
|---|---|---|
| 2024 | 10.1 | 27.8 |
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

Tiempo: 3.13 s

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
| 2026-01-01 | 5.86 | 29.04 |
| 2026-02-01 | 5.83 | 29.93 |
| 2026-03-01 | 5.07 | 23.83 |
| 2026-04-01 | 4.38 | 20.8 |
| 2026-05-01 | 4.65 | 23.24 |
| 2026-06-01 | 5.27 | 26.28 |
| 2026-07-01 | 5.51 | 27.33 |
| 2026-08-01 | 5.49 | 27.46 |
