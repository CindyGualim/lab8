# Resultados de `sql/ex4_analisis.sql`

Generado con `python scripts/run_sql.py sql/ex4_analisis.sql` el 2026-10-08 19:04 (DuckDB 1.5.5).

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

Tiempo: 4.81 s

| mes | tipo | viajes | viajes_por_dia | ingresos_musd | total_promedio |
|---|---|---|---|---|---|
| 2024-01 | yellow | 2859438 | 92,240 | 78.07 | 27.3 |
| 2024-02 | yellow | 2891599 | 99,710 | 78.65 | 27.2 |
| 2024-03 | yellow | 3428293 | 110,590 | 95.38 | 27.82 |
| 2024-04 | yellow | 3402667 | 113,422 | 95.78 | 28.15 |
| 2024-05 | yellow | 3605450 | 116,305 | 104.38 | 28.95 |
| 2024-06 | yellow | 3416216 | 113,874 | 97.86 | 28.65 |
| 2024-07 | yellow | 2962303 | 95,558 | 85.71 | 28.93 |
| 2024-08 | yellow | 2855660 | 92,118 | 83.3 | 29.17 |
| 2024-09 | yellow | 3471317 | 115,711 | 102.19 | 29.44 |
| 2024-10 | yellow | 3669091 | 118,358 | 107.62 | 29.33 |
| 2024-11 | yellow | 3497590 | 116,586 | 99.44 | 28.43 |
| 2024-12 | yellow | 3505884 | 113,093 | 102.82 | 29.33 |
| 2026-01 | yellow | 3506093 | 113,100 | 103.82 | 29.61 |
| 2026-02 | yellow | 3201435 | 114,337 | 97.32 | 30.4 |
| 2026-03 | yellow | 3751767 | 121,025 | 113.32 | 30.21 |
| 2026-04 | yellow | 3663832 | 122,128 | 110.03 | 30.03 |
| 2026-05 | yellow | 3900951 | 125,837 | 118.89 | 30.48 |
| 2026-06 | yellow | 3634844 | 121,161 | 110.95 | 30.52 |
| 2026-07 | yellow | 3335681 | 107,603 | 100.26 | 30.06 |
| 2026-08 | yellow | 3153755 | 101,734 | 94.83 | 30.07 |
| 2024-01 | green | 52763 | 1,702 | 1.17 | 22.2 |
| 2024-02 | green | 49921 | 1,721 | 1.12 | 22.5 |
| 2024-03 | green | 53597 | 1,729 | 1.22 | 22.78 |
| 2024-04 | green | 52370 | 1,746 | 1.22 | 23.3 |
| 2024-05 | green | 56840 | 1,834 | 1.39 | 24.5 |
| 2024-06 | green | 51122 | 1,704 | 1.26 | 24.74 |
| 2024-07 | green | 47996 | 1,548 | 1.17 | 24.45 |
| 2024-08 | green | 48062 | 1,550 | 1.24 | 25.87 |
| 2024-09 | green | 50669 | 1,689 | 1.34 | 26.51 |
| 2024-10 | green | 52611 | 1,697 | 1.31 | 24.97 |
| 2024-11 | green | 48585 | 1,620 | 1.17 | 23.99 |
| 2024-12 | green | 50073 | 1,615 | 1.19 | 23.8 |
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

Tiempo: 10.56 s

| hora | pct_yellow | pct_green | duracion_mediana_yellow | velocidad_mediana_yellow |
|---|---|---|---|---|
| 0 | 3.02 | 1.66 | 12.9 | 11.8 |
| 1 | 1.97 | 1.1 | 12 | 12.2 |
| 2 | 1.29 | 0.78 | 11.5 | 12.7 |
| 3 | 0.88 | 0.59 | 11.5 | 13.7 |
| 4 | 0.68 | 0.52 | 12.8 | 15.4 |
| 5 | 0.75 | 0.6 | 13 | 16.2 |
| 6 | 1.55 | 1.69 | 11.7 | 13.9 |
| 7 | 2.88 | 3.83 | 12 | 11.1 |
| 8 | 3.93 | 4.91 | 13.1 | 9.3 |
| 9 | 4.22 | 5.33 | 13.4 | 8.9 |
| 10 | 4.42 | 5.25 | 13.6 | 8.7 |
| 11 | 4.79 | 5.25 | 14.1 | 8.2 |
| 12 | 5.21 | 5.56 | 14.3 | 8.1 |
| 13 | 5.43 | 5.59 | 14.5 | 8.2 |
| 14 | 5.85 | 6.41 | 14.9 | 8.1 |
| 15 | 6.04 | 6.99 | 14.9 | 7.9 |
| 16 | 5.97 | 7.57 | 14.6 | 8.1 |
| 17 | 6.56 | 8.11 | 14.2 | 8.1 |
| 18 | 6.86 | 7.73 | 13.3 | 8.4 |
| 19 | 6.12 | 6 | 13 | 9.1 |
| 20 | 5.8 | 4.6 | 13 | 9.8 |
| 21 | 5.96 | 4.03 | 13.2 | 10.2 |
| 22 | 5.52 | 3.35 | 13.5 | 10.6 |
| 23 | 4.32 | 2.55 | 13.5 | 11.3 |

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

Tiempo: 4.77 s

| num_dia | dia | tipo | dias_observados | viajes_promedio_dia | pct_vs_promedio |
|---|---|---|---|---|---|
| 1 | Monday | yellow | 88 | 93,854 | -15.6 |
| 2 | Tuesday | yellow | 87 | 109,407 | -1.6 |
| 3 | Wednesday | yellow | 86 | 116,077 | 4.4 |
| 4 | Thursday | yellow | 87 | 122,181 | 9.8 |
| 5 | Friday | yellow | 87 | 115,607 | 3.9 |
| 6 | Saturday | yellow | 87 | 120,447 | 8.3 |
| 7 | Sunday | yellow | 87 | 101,002 | -9.2 |
| 1 | Monday | green | 88 | 1,513 | -1.4 |
| 2 | Tuesday | green | 87 | 1,617 | 5.4 |
| 3 | Wednesday | green | 86 | 1,690 | 10.1 |
| 4 | Thursday | green | 87 | 1,734 | 13 |
| 5 | Friday | green | 87 | 1,619 | 5.5 |
| 6 | Saturday | green | 87 | 1,340 | -12.6 |
| 7 | Sunday | green | 87 | 1,226 | -20.1 |

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

Tiempo: 25.73 s

| tipo | viajes | distancia_mediana_mi | distancia_promedio_mi | duracion_mediana_min | velocidad_mediana_mph | pasajeros_promedio | pct_un_pasajero | tarifa_mediana | total_mediano | tarifa_por_milla_mediana |
|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 67713866 | 1.85 | 3.47 | 13.6 | 9.3 | 1.3 | 79.2 | 14.9 | 22.2 | 7.42 |
| green | 934218 | 2.04 | 3.11 | 12.5 | 10.2 | 1.32 | 83 | 13.5 | 19.68 | 6.75 |

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

Tiempo: 9.16 s

| rango_distancia | pct_yellow | pct_green | total_mediano_yellow | total_mediano_green |
|---|---|---|---|---|
| 1) < 1 mi | 21.3 | 14.3 | 14.2 | 10.8 |
| 2) 1-2 mi | 31.9 | 34.3 | 18.9 | 15.48 |
| 3) 2-5 mi | 28.5 | 35.5 | 27.09 | 24.65 |
| 4) 5-10 mi | 10.3 | 11.4 | 43.75 | 41.8 |
| 5) 10-20 mi | 7.1 | 3.9 | 81.94 | 64.7 |
| 6) >= 20 mi | 1 | 0.4 | 99.75 | 108.8 |

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

Tiempo: 5.55 s

| borough | pct_yellow | pct_green |
|---|---|---|
| Manhattan | 88 | 60.6 |
| Queens | 8.97 | 23.52 |
| Brooklyn | 2.31 | 14.21 |
| Bronx | 0.49 | 1.54 |
| Unknown | 0.21 | 0.07 |
| N/A | 0.02 | 0.04 |
| Staten Island | 0.01 | 0.01 |
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

Tiempo: 5.86 s

| tipo | ranking | borough | zona | viajes | pct_del_tipo |
|---|---|---|---|---|---|
| yellow | 1 | Manhattan | Upper East Side South | 3119013 | 4.61 |
| yellow | 2 | Manhattan | Midtown Center | 3027745 | 4.47 |
| yellow | 3 | Queens | JFK Airport | 2961640 | 4.37 |
| yellow | 4 | Manhattan | Upper East Side North | 2798663 | 4.13 |
| yellow | 5 | Manhattan | Midtown East | 2242099 | 3.31 |
| yellow | 6 | Manhattan | Penn Station/Madison Sq West | 2189289 | 3.23 |
| yellow | 7 | Manhattan | Times Sq/Theatre District | 2150268 | 3.18 |
| yellow | 8 | Manhattan | Lincoln Square East | 2089510 | 3.09 |
| yellow | 9 | Queens | LaGuardia Airport | 1969291 | 2.91 |
| yellow | 10 | Manhattan | Murray Hill | 1873521 | 2.77 |
| green | 1 | Manhattan | East Harlem North | 233236 | 24.97 |
| green | 2 | Manhattan | East Harlem South | 130277 | 13.95 |
| green | 3 | Queens | Forest Hills | 46526 | 4.98 |
| green | 4 | Manhattan | Central Park | 44964 | 4.81 |
| green | 5 | Manhattan | Morningside Heights | 44945 | 4.81 |
| green | 6 | Queens | Elmhurst | 40037 | 4.29 |
| green | 7 | Manhattan | Central Harlem | 38636 | 4.14 |
| green | 8 | Brooklyn | Fort Greene | 29356 | 3.14 |
| green | 9 | Brooklyn | Downtown Brooklyn/MetroTech | 28672 | 3.07 |
| green | 10 | Queens | Jamaica | 23262 | 2.49 |

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

Tiempo: 5.71 s

| forma_pago | pct_yellow | pct_green | pct_yellow_con_info |
|---|---|---|---|
| 0 sin informacion / flex fare | 15.85 | 7.6 | 0 |
| 1 tarjeta de credito | 71.67 | 67.77 | 85.16 |
| 2 efectivo | 11.48 | 24.34 | 13.64 |
| 3 sin cargo | 0.29 | 0.2 | 0.35 |
| 4 disputa | 0.71 | 0.07 | 0.85 |
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

Tiempo: 8.34 s

| tipo | forma_pago | viajes | pct_con_propina | propina_promedio | propina_pct_de_tarifa | propina_pct_mediana_si_deja |
|---|---|---|---|---|---|---|
| yellow | tarjeta | 48527968 | 93.2 | 4.31 | 21.9 | 26.6 |
| yellow | sin informacion | 10730927 | 11.3 | 0.54 | 2.2 | 21.9 |
| yellow | efectivo | 7773194 | 0 | 0 | 0 | 26.7 |
| yellow | otro | 681777 | 0.1 | 0.01 | 0 | 26.6 |
| green | tarjeta | 633126 | 91.6 | 3.7 | 20.8 | 24.1 |
| green | efectivo | 227427 | 0 | 0 | 0 | 23.1 |
| green | sin informacion | 71044 | 35.8 | 1.69 | 11.4 | 20.7 |
| green | otro | 2621 | 0.2 | 0.01 | 0.1 | 27.4 |

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

Tiempo: 4.89 s

| hora | propina_pct_tarifa | pct_con_propina | distancia_promedio |
|---|---|---|---|
| 0 | 21.5 | 92.1 | 3.94 |
| 1 | 21.5 | 90.6 | 3.38 |
| 2 | 21.6 | 89.1 | 3.04 |
| 3 | 21 | 87.6 | 3.3 |
| 4 | 19.1 | 82.8 | 5.07 |
| 5 | 17.5 | 79.6 | 6.62 |
| 6 | 17.7 | 83.9 | 5.05 |
| 7 | 19.7 | 89.7 | 3.76 |
| 8 | 20.5 | 91.4 | 3.22 |
| 9 | 21 | 91.9 | 3.14 |
| 10 | 21.3 | 92.4 | 3.17 |
| 11 | 21.4 | 92.6 | 3.18 |
| 12 | 21.3 | 92.7 | 3.24 |
| 13 | 21.5 | 93 | 3.42 |
| 14 | 21.5 | 93.3 | 3.59 |
| 15 | 21.4 | 93.5 | 3.55 |
| 16 | 22.6 | 93.6 | 3.55 |
| 17 | 23.1 | 94.3 | 3.14 |
| 18 | 23.6 | 94.9 | 2.96 |
| 19 | 23.5 | 94.8 | 3.18 |
| 20 | 22.9 | 95 | 3.4 |
| 21 | 22.9 | 95.3 | 3.44 |
| 22 | 22.5 | 94.8 | 3.61 |
| 23 | 21.9 | 93.5 | 4.01 |

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

Tiempo: 6.42 s

| tipo | tarifa | extra | mta_tax | improvement_surcharge | congestion_surcharge | cbd_congestion_fee | airport_fee | peajes | propina | total | pct_tarifa_en_total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 20.37 | 1.33 | 0.5 | 0.99 | 2.3 | 0.23 | 0.16 | 0.57 | 3.17 | 29.25 | 69.6 |
| green | 17.58 | 0.93 | 0.57 | 0.96 | 0.88 | 0.02 | 0 | 0.25 | 2.64 | 24.55 | 71.6 |

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

Tiempo: 6.52 s

| tipo | pct_viajes_aeropuerto | pct_ingresos_aeropuerto | total_mediano_aeropuerto | pct_con_cuota_cbd | cuota_cbd_musd |
|---|---|---|---|---|---|
| yellow | 9.25 | 24.86 | 79.34 | 30.14 | 15.31 |
| green | 3.93 | 7.58 | 36.6 | 2.93 | 0.02 |

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

Tiempo: 5.25 s

| tipo | motivo | registros | pct_del_tipo |
|---|---|---|---|
| yellow | (valido) | 67713866 | 95.54 |
| yellow | distancia = 0 | 1162071 | 1.64 |
| yellow | duracion < 1 min | 797532 | 1.13 |
| yellow | monto negativo | 781753 | 1.1 |
| yellow | duracion <= 0 | 385192 | 0.54 |
| yellow | duracion > 6 h | 29303 | 0.04 |
| yellow | distancia > 100 mi | 2783 | 0 |
| yellow | fecha fuera del mes del archivo | 566 | 0 |
| yellow | total >= 1000 | 9 | 0 |
| green | (valido) | 934218 | 93.67 |
| green | duracion < 1 min | 30998 | 3.11 |
| green | distancia = 0 | 25793 | 2.59 |
| green | duracion > 6 h | 3723 | 0.37 |
| green | monto negativo | 1141 | 0.11 |
| green | duracion <= 0 | 894 | 0.09 |
| green | distancia > 100 mi | 303 | 0.03 |
| green | fecha fuera del mes del archivo | 262 | 0.03 |

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

Tiempo: 19.49 s

| tipo | tarifa_milla_q1 | tarifa_milla_q3 | limite_superior_iqr | atipicos_tarifa_milla | pct_atipicos_tarifa_milla | velocidad_mayor_80mph | tarifa_cero | tarifa_negociada |
|---|---|---|---|---|---|---|---|---|
| yellow | 5.75 | 9.62 | 15.43 | 3436573 | 5.08 | 6189 | 19777 | 249907 |
| green | 5.62 | 8.17 | 12 | 46469 | 4.97 | 253 | 4866 | 27769 |
