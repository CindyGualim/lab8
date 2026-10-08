# Resultados de `scripts/benchmark.py`

Generado el 2026-10-08 20:54 (DuckDB 1.5.5). Cada tiempo es la mediana de 3 ejecuciones.

## Datos y costo de materializar

| Datos | Registros | Archivos Parquet (MiB) | Tabla DuckDB (MiB) | Tiempo de creacion (s) |
|---|---|---|---|---|
| 1 mes (2026-01) | 3,765,161 | 62 | 131 | 5.9 |
| 1 anio (2026) | 30,040,469 | 496 | 1,039 | 32.3 |
| 2 anios (2024 y 2026) | 71,870,407 | 1,172 | 2,474 | 77.3 |
| 3 anios (2024 a 2026) | 121,184,384 | 1,977 | 4,210 | 135.4 |

## Tiempos por consulta

| Datos | Consulta | Parquet (s) | Tabla (s) | Parquet / Tabla |
|---|---|---|---|---|
| 1 mes (2026-01) | B1 Conteo de viajes validos por tipo | 0.937 | 0.021 | 43.7x |
| 1 mes (2026-01) | B2 Volumen mensual e ingresos por tipo (Q4.1) | 0.821 | 0.062 | 13.3x |
| 1 mes (2026-01) | B3 Medianas del viaje tipico por tipo (Q4.4) | 1.273 | 0.628 | 2.0x |
| 1 mes (2026-01) | B4 Borough de origen con join a zonas (Q4.6) | 0.974 | 0.069 | 14.2x |
| 1 mes (2026-01) | B5 Filtro selectivo: primera semana de enero 2026 | 0.373 | 0.012 | 31.8x |
| 1 anio (2026) | B1 Conteo de viajes validos por tipo | 5.177 | 0.178 | 29.0x |
| 1 anio (2026) | B2 Volumen mensual e ingresos por tipo (Q4.1) | 4.695 | 0.394 | 11.9x |
| 1 anio (2026) | B3 Medianas del viaje tipico por tipo (Q4.4) | 10.327 | 5.295 | 2.0x |
| 1 anio (2026) | B4 Borough de origen con join a zonas (Q4.6) | 6.187 | 0.406 | 15.2x |
| 1 anio (2026) | B5 Filtro selectivo: primera semana de enero 2026 | 0.725 | 0.025 | 29.4x |
| 2 anios (2024 y 2026) | B1 Conteo de viajes validos por tipo | 9.847 | 0.283 | 34.8x |
| 2 anios (2024 y 2026) | B2 Volumen mensual e ingresos por tipo (Q4.1) | 9.383 | 0.735 | 12.8x |
| 2 anios (2024 y 2026) | B3 Medianas del viaje tipico por tipo (Q4.4) | 22.599 | 13.198 | 1.7x |
| 2 anios (2024 y 2026) | B4 Borough de origen con join a zonas (Q4.6) | 11.205 | 0.824 | 13.6x |
| 2 anios (2024 y 2026) | B5 Filtro selectivo: primera semana de enero 2026 | 1.102 | 0.019 | 56.6x |
| 3 anios (2024 a 2026) | B1 Conteo de viajes validos por tipo | 22.198 | 0.717 | 31.0x |
| 3 anios (2024 a 2026) | B2 Volumen mensual e ingresos por tipo (Q4.1) | 15.649 | 1.731 | 9.0x |
| 3 anios (2024 a 2026) | B3 Medianas del viaje tipico por tipo (Q4.4) | 40.780 | 26.323 | 1.5x |
| 3 anios (2024 a 2026) | B4 Borough de origen con join a zonas (Q4.6) | 18.295 | 1.398 | 13.1x |
| 3 anios (2024 a 2026) | B5 Filtro selectivo: primera semana de enero 2026 | 1.250 | 0.020 | 61.7x |
