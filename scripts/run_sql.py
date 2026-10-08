#!/usr/bin/env python3
"""Ejecuta un archivo .sql con DuckDB y guarda los resultados en Markdown.

El archivo SQL se divide en bloques con comentarios "-- name: <titulo>".
Las sentencias antes del primer bloque (p. ej. CREATE VIEW) se ejecutan como
preparacion. Cada bloque se ejecuta por separado y su resultado se escribe en
docs/resultados/<nombre-del-sql>.md junto con la consulta y el tiempo.

Uso:
    python scripts/run_sql.py sql/ex3_exploracion.sql
    python scripts/run_sql.py sql/ex3_exploracion.sql --db data/processed/taxis.duckdb

Las rutas de los archivos Parquet dentro del SQL son relativas a la raiz del
proyecto, por lo que el script siempre se ejecuta desde ahi.
"""

import argparse
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

import duckdb

RAIZ_PROYECTO = Path(__file__).resolve().parent.parent
DIR_RESULTADOS = RAIZ_PROYECTO / "docs" / "resultados"
MAX_FILAS = 60          # filas mostradas por resultado
MAX_ANCHO_CELDA = 60    # caracteres por celda

PATRON_BLOQUE = re.compile(r"^--\s*name:\s*(.+)$", re.MULTILINE)


def dividir_bloques(sql: str) -> tuple[str, list[tuple[str, str]]]:
    """Devuelve (preparacion, [(titulo, consulta), ...])."""
    partes = PATRON_BLOQUE.split(sql)
    preparacion = partes[0]
    bloques = [(partes[i].strip(), partes[i + 1].strip())
               for i in range(1, len(partes), 2)]
    return preparacion, bloques


def formato_celda(valor) -> str:
    if valor is None:
        texto = "NULL"
    elif isinstance(valor, float):
        texto = f"{valor:,.4f}".rstrip("0").rstrip(".")
    elif isinstance(valor, list):
        texto = "[" + ", ".join(formato_celda(v) for v in valor) + "]"
    else:
        texto = str(valor)
    texto = texto.replace("|", "\\|").replace("\n", " ")
    if len(texto) > MAX_ANCHO_CELDA:
        texto = texto[: MAX_ANCHO_CELDA - 1] + "…"
    return texto


def tabla_markdown(columnas: list[str], filas: list[tuple]) -> str:
    lineas = ["| " + " | ".join(columnas) + " |",
              "|" + "|".join("---" for _ in columnas) + "|"]
    for fila in filas[:MAX_FILAS]:
        lineas.append("| " + " | ".join(formato_celda(v) for v in fila) + " |")
    if len(filas) > MAX_FILAS:
        lineas.append(f"\n_({len(filas) - MAX_FILAS} filas adicionales omitidas)_")
    return "\n".join(lineas)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("sql", type=Path, help="archivo .sql a ejecutar")
    parser.add_argument("--db", default=":memory:",
                        help="base DuckDB a usar (por defecto: en memoria)")
    argumentos = parser.parse_args()

    ruta_sql = argumentos.sql.resolve()
    os.chdir(RAIZ_PROYECTO)
    preparacion, bloques = dividir_bloques(ruta_sql.read_text(encoding="utf-8"))

    conexion = duckdb.connect(argumentos.db)
    if preparacion.strip():
        conexion.execute(preparacion)

    salida = [
        f"# Resultados de `{ruta_sql.relative_to(RAIZ_PROYECTO).as_posix()}`",
        "",
        f"Generado con `python scripts/run_sql.py "
        f"{ruta_sql.relative_to(RAIZ_PROYECTO).as_posix()}` el "
        f"{datetime.now():%Y-%m-%d %H:%M} (DuckDB {duckdb.__version__}).",
        "",
    ]
    errores = 0
    for titulo, consulta in bloques:
        print(f"-> {titulo}")
        inicio = time.perf_counter()
        try:
            relacion = conexion.execute(consulta)
            filas = relacion.fetchall()
            columnas = [d[0] for d in relacion.description]
        except duckdb.Error as error:
            errores += 1
            print(f"   ERROR: {error}")
            resultado = f"**ERROR:** `{error}`"
        else:
            resultado = tabla_markdown(columnas, filas)
        segundos = time.perf_counter() - inicio
        print(f"   {segundos:.2f} s")

        salida += [f"## {titulo}", "", "```sql", consulta, "```", "",
                   f"Tiempo: {segundos:.2f} s", "", resultado, ""]

    DIR_RESULTADOS.mkdir(parents=True, exist_ok=True)
    destino = DIR_RESULTADOS / f"{ruta_sql.stem}.md"
    destino.write_text("\n".join(salida), encoding="utf-8")
    print(f"\nResultados guardados en {destino.relative_to(RAIZ_PROYECTO).as_posix()}")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
