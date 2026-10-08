#!/usr/bin/env python3
"""Materializa los viajes en una base DuckDB (Ejercicio 6).

Usa las mismas vistas del Ejercicio 4 (sql/ex4_analisis.sql) para leer los
Parquet y guarda el resultado como tablas:

    viajes          tabla con amarillos + verdes normalizados (incluye motivo_exclusion)
    zonas           tabla de zonas de la TLC
    viajes_validos  vista sobre la tabla viajes, con la misma definicion del Ej. 4

Uso:
    python scripts/construir_db.py                                  # todos los anios -> data/processed/taxis.duckdb
    python scripts/construir_db.py --patron "2026/*" --db data/processed/otra.duckdb
"""

import argparse
import os
import time
from pathlib import Path

import duckdb

from run_sql import dividir_bloques

RAIZ_PROYECTO = Path(__file__).resolve().parent.parent
DB_POR_DEFECTO = "data/processed/taxis.duckdb"


def preparacion_parquet(patron: str = "*/*") -> str:
    """Vistas del Ejercicio 4 apuntando solo a los archivos data/raw/<tipo>/<patron>.parquet."""
    sql = (RAIZ_PROYECTO / "sql" / "ex4_analisis.sql").read_text(encoding="utf-8")
    preparacion = dividir_bloques(sql)[0]
    return preparacion.replace("/*/*.parquet", f"/{patron}.parquet")


def construir(db: str = DB_POR_DEFECTO, patron: str = "*/*") -> float:
    """Crea (o reemplaza) la base y devuelve los segundos que tardo."""
    os.chdir(RAIZ_PROYECTO)
    Path(db).unlink(missing_ok=True)
    preparacion = preparacion_parquet(patron)
    vista_validos = next(s for s in preparacion.split(";") if "VIEW viajes_validos" in s)

    inicio = time.perf_counter()
    con = duckdb.connect()
    con.execute(preparacion)
    con.execute(f"ATTACH '{db}' AS destino")
    con.execute("CREATE TABLE destino.viajes AS SELECT * FROM viajes")
    con.execute("CREATE TABLE destino.zonas AS SELECT * FROM zonas")
    con.close()

    con = duckdb.connect(db)
    con.execute(vista_validos)
    con.close()
    return time.perf_counter() - inicio


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--db", default=DB_POR_DEFECTO)
    parser.add_argument("--patron", default="*/*",
                        help='archivos a incluir dentro de data/raw/<tipo>/ (por defecto "*/*")')
    argumentos = parser.parse_args()

    segundos = construir(argumentos.db, argumentos.patron)
    con = duckdb.connect(argumentos.db, read_only=True)
    filas = con.sql("SELECT count(*) FROM viajes").fetchone()[0]
    print(f"{argumentos.db}: {filas:,} filas, {segundos:.1f} s, "
          f"{Path(argumentos.db).stat().st_size / 1024**2:,.0f} MiB")


if __name__ == "__main__":
    main()
