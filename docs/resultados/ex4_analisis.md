# Resultados de `sql/ex4_analisis.sql`

Generado con `python scripts/run_sql.py sql/ex4_analisis.sql` el 2026-10-08 18:35 (DuckDB 1.5.5).

## Q4.1 Volumen mensual de viajes e ingresos por tipo

```sql
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
```

Tiempo: 2.11 s

| mes | tipo | viajes | viajes_por_dia | ingresos_musd | total_promedio |
|---|---|---|---|---|---|
| 2026-01 | yellow | 3506093 | 113,100 | 103.82 | 29.61 |
| 2026-02 | yellow | 3201435 | 114,337 | 97.32 | 30.4 |
| 2026-03 | yellow | 3751767 | 121,025 | 113.32 | 30.21 |
| 2026-04 | yellow | 3663832 | 122,128 | 110.03 | 30.03 |
| 2026-05 | yellow | 3900951 | 125,837 | 118.89 | 30.48 |
| 2026-06 | yellow | 3634844 | 121,161 | 110.95 | 30.52 |
| 2026-07 | yellow | 3335681 | 107,603 | 100.26 | 30.06 |
| 2026-08 | yellow | 3153755 | 101,734 | 94.83 | 30.07 |
| 2026-01 | green | 38313 | 1,236 | 0.93 | 24.22 |
| 2026-02 | green | 35380 | 1,264 | 0.86 | 24.32 |
| 2026-03 | green | 42069 | 1,357 | 1.05 | 24.88 |
| 2026-04 | green | 41952 | 1,398 | 1.06 | 25.3 |
| 2026-05 | green | 42655 | 1,376 | 1.1 | 25.73 |
| 2026-06 | green | 42001 | 1,400 | 1.09 | 26.03 |
| 2026-07 | green | 38933 | 1,256 | 1.02 | 26.11 |
| 2026-08 | green | 38306 | 1,236 | 1.01 | 26.34 |

## Q4.2 Distribucion de viajes por hora del dia (% del total de cada tipo)

```sql
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
```

Tiempo: 4.22 s

| hora | pct_yellow | pct_green | duracion_mediana_yellow | velocidad_mediana_yellow |
|---|---|---|---|---|
| 0 | 3.21 | 1.45 | 13.8 | 11.8 |
| 1 | 2.13 | 0.88 | 13.1 | 12.3 |
| 2 | 1.42 | 0.64 | 12.7 | 12.9 |
| 3 | 1.02 | 0.51 | 12.7 | 13.8 |
| 4 | 0.83 | 0.52 | 13.7 | 15.4 |
| 5 | 0.92 | 0.75 | 13.7 | 16 |
| 6 | 1.74 | 2.04 | 12.9 | 13.8 |
| 7 | 3.04 | 4.32 | 13.1 | 11.1 |
| 8 | 4.08 | 5.44 | 14.1 | 9.3 |
| 9 | 4.27 | 5.7 | 14.2 | 8.9 |
| 10 | 4.32 | 5.51 | 14.4 | 8.6 |
| 11 | 4.67 | 5.44 | 14.8 | 8.1 |
| 12 | 5.04 | 5.88 | 14.8 | 8.1 |
| 13 | 5.28 | 5.79 | 15 | 8.1 |
| 14 | 5.72 | 6.47 | 15.3 | 8 |
| 15 | 5.91 | 7.01 | 15.4 | 7.9 |
| 16 | 5.66 | 7.56 | 14.9 | 8 |
| 17 | 6.26 | 7.8 | 14.4 | 8 |
| 18 | 6.49 | 7.35 | 13.6 | 8.3 |
| 19 | 5.9 | 5.5 | 13.4 | 8.9 |
| 20 | 5.87 | 4.21 | 13.6 | 9.8 |
| 21 | 6.09 | 3.73 | 13.8 | 10.1 |
| 22 | 5.65 | 3.19 | 14.2 | 10.5 |
| 23 | 4.48 | 2.28 | 14.2 | 11.2 |

## Q4.3 Viajes promedio por dia de la semana

```sql
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
```

Tiempo: 1.94 s

| num_dia | dia | tipo | dias_observados | viajes_promedio_dia | pct_vs_promedio |
|---|---|---|---|---|---|
| 1 | Monday | yellow | 35 | 95,571 | -17.5 |
| 2 | Tuesday | yellow | 34 | 112,852 | -2.6 |
| 3 | Wednesday | yellow | 34 | 120,279 | 3.8 |
| 4 | Thursday | yellow | 35 | 127,057 | 9.7 |
| 5 | Friday | yellow | 35 | 120,283 | 3.8 |
| 6 | Saturday | yellow | 35 | 128,254 | 10.7 |
| 7 | Sunday | yellow | 35 | 106,604 | -8 |
| 1 | Monday | green | 35 | 1,306 | -0.8 |
| 2 | Tuesday | green | 34 | 1,425 | 8.3 |
| 3 | Wednesday | green | 34 | 1,479 | 12.4 |
| 4 | Thursday | green | 35 | 1,512 | 14.9 |
| 5 | Friday | green | 35 | 1,370 | 4.1 |
| 6 | Saturday | green | 35 | 1,091 | -17.1 |
| 7 | Sunday | green | 35 | 1,031 | -21.7 |

## Q4.4 Caracteristicas del viaje tipico por tipo de taxi

```sql
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
```

Tiempo: 8.61 s

| tipo | viajes | distancia_mediana_mi | distancia_promedio_mi | duracion_mediana_min | velocidad_mediana_mph | pasajeros_promedio | pct_un_pasajero | tarifa_mediana | total_mediano | tarifa_por_milla_mediana |
|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 28148358 | 1.94 | 3.53 | 14.2 | 9.3 | 1.25 | 82.3 | 15.6 | 23.58 | 7.54 |
| green | 319609 | 2.17 | 3.38 | 13.4 | 10 | 1.3 | 82.9 | 13.5 | 20.52 | 6.67 |

## Q4.5 Distribucion de la distancia del viaje (% por rango)

```sql
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
```

Tiempo: 3.79 s

| rango_distancia | pct_yellow | pct_green | total_mediano_yellow | total_mediano_green |
|---|---|---|---|---|
| 1) < 1 mi | 20.7 | 13 | 14.75 | 11.25 |
| 2) 1-2 mi | 30.3 | 32.8 | 19.74 | 16 |
| 3) 2-5 mi | 29.2 | 35.9 | 28.1 | 24.66 |
| 4) 5-10 mi | 12 | 12.6 | 42.95 | 40.2 |
| 5) 10-20 mi | 6.8 | 5.3 | 78.62 | 55.5 |
| 6) >= 20 mi | 0.9 | 0.5 | 100.65 | 93.22 |

## Q4.6 Borough de origen de los viajes (% por tipo)

```sql
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
```

Tiempo: 2.53 s

| borough | pct_yellow | pct_green |
|---|---|---|
| Manhattan | 86.74 | 59.83 |
| Queens | 8.75 | 21.8 |
| Brooklyn | 3.6 | 15.74 |
| Bronx | 0.78 | 2.47 |
| Unknown | 0.1 | 0.09 |
| N/A | 0.02 | 0.05 |
| Staten Island | 0.01 | 0.02 |
| EWR | 0 | 0 |

## Q4.7 Diez zonas de abordaje con mas viajes por tipo

```sql
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
```

Tiempo: 2.58 s

| tipo | ranking | borough | zona | viajes | pct_del_tipo |
|---|---|---|---|---|---|
| yellow | 1 | Manhattan | Upper East Side South | 1250862 | 4.44 |
| yellow | 2 | Manhattan | Midtown Center | 1169840 | 4.16 |
| yellow | 3 | Queens | JFK Airport | 1112008 | 3.95 |
| yellow | 4 | Manhattan | Upper East Side North | 1111149 | 3.95 |
| yellow | 5 | Manhattan | Penn Station/Madison Sq West | 867486 | 3.08 |
| yellow | 6 | Manhattan | Midtown East | 863339 | 3.07 |
| yellow | 7 | Manhattan | Times Sq/Theatre District | 815655 | 2.9 |
| yellow | 8 | Manhattan | Lincoln Square East | 810586 | 2.88 |
| yellow | 9 | Manhattan | East Village | 755195 | 2.68 |
| yellow | 10 | Manhattan | Murray Hill | 736340 | 2.62 |
| green | 1 | Manhattan | East Harlem North | 86800 | 27.16 |
| green | 2 | Manhattan | East Harlem South | 41726 | 13.06 |
| green | 3 | Queens | Forest Hills | 15576 | 4.87 |
| green | 4 | Manhattan | Central Park | 12972 | 4.06 |
| green | 5 | Manhattan | Morningside Heights | 12432 | 3.89 |
| green | 6 | Queens | Elmhurst | 11001 | 3.44 |
| green | 7 | Manhattan | Central Harlem | 10956 | 3.43 |
| green | 8 | Brooklyn | Downtown Brooklyn/MetroTech | 10483 | 3.28 |
| green | 9 | Queens | Jamaica | 8948 | 2.8 |
| green | 10 | Brooklyn | Fort Greene | 8682 | 2.72 |

## Q4.8 Forma de pago por tipo de taxi (% de viajes)

```sql
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
```

Tiempo: 2.19 s

| forma_pago | pct_yellow | pct_green | pct_yellow_con_info |
|---|---|---|---|
| 0 sin informacion / flex fare | 25.01 | 14.9 | 0 |
| 1 tarjeta de credito | 65.4 | 65.59 | 87.21 |
| 2 efectivo | 9 | 19.28 | 12 |
| 3 sin cargo | 0.19 | 0.16 | 0.26 |
| 4 disputa | 0.4 | 0.07 | 0.54 |
| 5 desconocido | 0 | 0 | 0 |

## Q4.9 Propinas segun la forma de pago

```sql
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
```

Tiempo: 3.06 s

| tipo | forma_pago | viajes | pct_con_propina | propina_promedio | propina_pct_de_tarifa | propina_pct_mediana_si_deja |
|---|---|---|---|---|---|---|
| yellow | tarjeta | 18409415 | 91.1 | 4.24 | 21.6 | 27.3 |
| yellow | sin informacion | 7038788 | 8.3 | 0.4 | 1.6 | 21.6 |
| yellow | efectivo | 2532774 | 0 | 0 | 0 | 27.6 |
| yellow | otro | 167381 | 0 | 0 | 0 | 26.9 |
| green | tarjeta | 209645 | 91.7 | 3.8 | 21.1 | 24.3 |
| green | efectivo | 61630 | 0 | 0 | 0 | NULL |
| green | sin informacion | 47607 | 15.5 | 0.76 | 8 | 20.8 |
| green | otro | 727 | 0.1 | 0 | 0 | 29.3 |

## Q4.10 Propina con tarjeta segun la hora del dia

```sql
SELECT
    hour(pickup)                                                       AS hora,
    round(100.0 * sum(tip_amount) / sum(fare_amount), 1)               AS propina_pct_tarifa,
    round(100.0 * count(*) FILTER (WHERE tip_amount > 0) / count(*), 1) AS pct_con_propina,
    round(avg(trip_distance), 2)                                       AS distancia_promedio
FROM viajes_validos
WHERE tipo = 'yellow' AND payment_type = 1 AND fare_amount > 0
GROUP BY hora
ORDER BY hora;
```

Tiempo: 1.69 s

| hora | propina_pct_tarifa | pct_con_propina | distancia_promedio |
|---|---|---|---|
| 0 | 21.5 | 90.1 | 3.94 |
| 1 | 21.4 | 88.2 | 3.42 |
| 2 | 21.3 | 86.5 | 3.13 |
| 3 | 20.5 | 84.3 | 3.36 |
| 4 | 18 | 78 | 5.07 |
| 5 | 15.8 | 73.1 | 6.56 |
| 6 | 16.2 | 78.3 | 5.1 |
| 7 | 18.7 | 85.8 | 3.81 |
| 8 | 19.7 | 88.2 | 3.25 |
| 9 | 20.3 | 89.1 | 3.15 |
| 10 | 20.8 | 90.1 | 3.15 |
| 11 | 20.9 | 90.6 | 3.17 |
| 12 | 21 | 90.7 | 3.17 |
| 13 | 21.2 | 91.1 | 3.31 |
| 14 | 21.2 | 91.5 | 3.53 |
| 15 | 21.1 | 91.7 | 3.53 |
| 16 | 22.3 | 91.7 | 3.5 |
| 17 | 22.9 | 92.6 | 3.12 |
| 18 | 23.5 | 93.4 | 2.92 |
| 19 | 23.5 | 93.4 | 3.16 |
| 20 | 22.9 | 93.6 | 3.35 |
| 21 | 22.9 | 94 | 3.37 |
| 22 | 22.5 | 93.3 | 3.56 |
| 23 | 21.9 | 91.6 | 3.93 |

## Q4.11 Composicion del monto total (promedio por viaje, USD)

```sql
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
```

Tiempo: 2.69 s

| tipo | tarifa | extra | mta_tax | improvement_surcharge | congestion_surcharge | cbd_congestion_fee | airport_fee | peajes | propina | total | pct_tarifa_en_total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 21.23 | 1.17 | 0.5 | 0.98 | 2.26 | 0.54 | 0.17 | 0.55 | 2.88 | 30.18 | 70.3 |
| green | 16.71 | 0.84 | 0.56 | 0.92 | 0.92 | 0.06 | 0 | 0.3 | 2.6 | 25.38 | 65.8 |

## Q4.12 Viajes de aeropuerto y cuota de congestion CBD

```sql
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
```

Tiempo: 2.48 s

| tipo | pct_viajes_aeropuerto | pct_ingresos_aeropuerto | total_mediano_aeropuerto | pct_con_cuota_cbd | cuota_cbd_musd |
|---|---|---|---|---|---|
| yellow | 8.1 | 20.93 | 78.33 | 72.51 | 15.31 |
| green | 3.36 | 6.41 | 40 | 8.57 | 0.02 |

## Q4.13 Registros excluidos por motivo (valores atipicos e inconsistencias)

```sql
SELECT
    tipo,
    coalesce(motivo_exclusion, '(valido)')                       AS motivo,
    count(*)                                                     AS registros,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo), 2) AS pct_del_tipo
FROM viajes
GROUP BY tipo, motivo
ORDER BY tipo DESC, registros DESC;
```

Tiempo: 2.07 s

| tipo | motivo | registros | pct_del_tipo |
|---|---|---|---|
| yellow | (valido) | 28148358 | 94.76 |
| yellow | distancia = 0 | 728621 | 2.45 |
| yellow | duracion <= 0 | 371682 | 1.25 |
| yellow | duracion < 1 min | 309476 | 1.04 |
| yellow | monto negativo | 136567 | 0.46 |
| yellow | duracion > 6 h | 7309 | 0.02 |
| yellow | distancia > 100 mi | 1194 | 0 |
| yellow | fecha fuera del mes del archivo | 146 | 0 |
| yellow | total >= 1000 | 2 | 0 |
| green | (valido) | 319609 | 94.81 |
| green | duracion < 1 min | 11028 | 3.27 |
| green | distancia = 0 | 4628 | 1.37 |
| green | duracion > 6 h | 1096 | 0.33 |
| green | monto negativo | 350 | 0.1 |
| green | duracion <= 0 | 234 | 0.07 |
| green | fecha fuera del mes del archivo | 98 | 0.03 |
| green | distancia > 100 mi | 71 | 0.02 |

## Q4.14 Valores atipicos entre viajes validos (regla IQR y velocidad)

```sql
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
```

Tiempo: 7.45 s

| tipo | tarifa_milla_q1 | tarifa_milla_q3 | limite_superior_iqr | atipicos_tarifa_milla | pct_atipicos_tarifa_milla | velocidad_mayor_80mph | tarifa_cero | tarifa_negociada |
|---|---|---|---|---|---|---|---|---|
| yellow | 5.72 | 9.91 | 16.19 | 1577017 | 5.6 | 4233 | 12522 | 119499 |
| green | 5.33 | 8.14 | 12.36 | 14500 | 4.54 | 95 | 4723 | 10095 |
