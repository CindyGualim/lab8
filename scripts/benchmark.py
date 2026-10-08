#!/usr/bin/env python3
"""Benchmark: consultas sobre Parquet directo vs. tabla materializada (Ejercicio 6).

Para cada cantidad de datos (NIVELES):
  1. crea una base DuckDB con esos datos (scripts/construir_db.py);
  2. ejecuta cada consulta de sql/ex6_benchmark.sql REPETICIONES veces sobre
     los Parquet y sobre la tabla, y guarda la mediana del tiempo.

El ultimo nivel (los 3 anios) queda guardado en data/processed/taxis.duckdb,
que es la base que usa Metabase. Los resultados se escriben en
docs/resultados/ex6_benchmark.md.

Uso:
    python scripts/benchmark.py
"""

import os
import statistics
import time
from datetime import datetime
from pathlib import Path

import duckdb

from construir_db import DB_POR_DEFECTO, construir, preparacion_parquet
from run_sql import dividir_bloques

RAIZ_PROYECTO = Path(__file__).resolve().parent.parent
REPETICIONES = 3
DB_TEMPORAL = "data/processed/benchmark_tmp.duckdb"

# (nombre, patron dentro de data/raw/<tipo>/, base donde se materializa)
NIVELES = [
    ("1 mes (2026-01)", "2026/*2026-01", DB_TEMPORAL),
    ("1 anio (2026)", "2026/*", DB_TEMPORAL),
    ("2 anios (2024 y 2026)", "202[46]/*", DB_TEMPORAL),
    ("3 anios (2024 a 2026)", "*/*", DB_POR_DEFECTO),
]


def medir(con: duckdb.DuckDBPyConnection, consulta: str) -> float:
    """Mediana en segundos de REPETICIONES ejecuciones de la consulta."""
    tiempos = []
    for _ in range(REPETICIONES):
        inicio = time.perf_counter()
        con.execute(consulta).fetchall()
        tiempos.append(time.perf_counter() - inicio)
    return statistics.median(tiempos)


def main() -> None:
    os.chdir(RAIZ_PROYECTO)
    consultas = dividir_bloques(Path("sql/ex6_benchmark.sql").read_text(encoding="utf-8"))[1]

    resumen = ["| Datos | Registros | Archivos Parquet (MiB) | Tabla DuckDB (MiB) | Tiempo de creacion (s) |",
               "|---|---|---|---|---|"]
    detalle = ["| Datos | Consulta | Parquet (s) | Tabla (s) | Parquet / Tabla |",
               "|---|---|---|---|---|"]

    for nombre, patron, db in NIVELES:
        print(f"== {nombre}")
        segundos_creacion = construir(db, patron)

        parquet = duckdb.connect()
        parquet.execute(preparacion_parquet(patron))
        tabla = duckdb.connect(db, read_only=True)

        registros = tabla.sql("SELECT count(*) FROM viajes").fetchone()[0]
        mib_parquet = parquet.sql(
            f"SELECT sum(file_size_bytes) / 1024 / 1024 FROM parquet_file_metadata('data/raw/*/{patron}.parquet')"
        ).fetchone()[0]
        mib_tabla = Path(db).stat().st_size / 1024 / 1024
        resumen.append(f"| {nombre} | {registros:,} | {mib_parquet:,.0f} | {mib_tabla:,.0f} | {segundos_creacion:.1f} |")

        for titulo, consulta in consultas:
            t_parquet = medir(parquet, consulta)
            t_tabla = medir(tabla, consulta)
            print(f"   {titulo[:2]}  parquet {t_parquet:.3f} s  tabla {t_tabla:.3f} s")
            detalle.append(f"| {nombre} | {titulo} | {t_parquet:.3f} | {t_tabla:.3f} | {t_parquet / t_tabla:.1f}x |")

        parquet.close()
        tabla.close()
        if db == DB_TEMPORAL:
            Path(db).unlink()

    salida = ["# Resultados de `scripts/benchmark.py`", "",
              f"Generado el {datetime.now():%Y-%m-%d %H:%M} (DuckDB {duckdb.__version__}). "
              f"Cada tiempo es la mediana de {REPETICIONES} ejecuciones.", "",
              "## Datos y costo de materializar", "", *resumen, "",
              "## Tiempos por consulta", "", *detalle, ""]
    destino = RAIZ_PROYECTO / "docs" / "resultados" / "ex6_benchmark.md"
    destino.write_text("\n".join(salida), encoding="utf-8")
    print(f"\nResultados guardados en {destino.relative_to(RAIZ_PROYECTO).as_posix()}")


if __name__ == "__main__":
    main()
