#!/usr/bin/env python3
"""Crea en Metabase el tablero de indicadores del Ejercicio 7.

Pasos (API de Metabase):
  1. si Metabase no esta configurado, crea el usuario administrador;
  2. registra la base data/processed/taxis.duckdb en modo de solo lectura;
  3. crea una pregunta SQL por cada bloque de sql/ex7_indicadores.sql;
  4. arma el tablero con todas las preguntas.

Se ejecuta dentro del contenedor lab, despues de scripts/construir_db.py:
    python scripts/metabase_tablero.py

Las credenciales son solo para el Metabase local y se pueden cambiar con las
variables MB_EMAIL y MB_PASSWORD.
"""

import os
import sys
from pathlib import Path

import requests

from run_sql import dividir_bloques

RAIZ_PROYECTO = Path(__file__).resolve().parent.parent
URL = os.environ.get("MB_URL", "http://metabase:3000")
EMAIL = os.environ.get("MB_EMAIL", "admin@lab8.local")
PASSWORD = os.environ.get("MB_PASSWORD", "lab8-duckdb-2026")
NOMBRE_DB = "Taxis NYC (DuckDB)"
NOMBRE_TABLERO = "Taxis NYC - Indicadores"

# indicador: (tipo de grafico, eje x y series, metricas, ajustes extra)
GRAFICOS = {
    "I1": ("line", ["mes", "tipo"], ["viajes_por_dia"], {"graph.y_axis.scale": "log"}),
    "I2": ("line", ["hora", "tipo"], ["pct_viajes"], {}),
    "I3": ("bar", ["dia", "tipo"], ["pct_vs_promedio"], {}),
    "I4": ("line", ["mes"], ["tarifa_mediana", "total_promedio"], {}),
    "I5": ("bar", ["grupo", "forma_pago"], ["pct_viajes"], {"stackable.stack_type": "stacked"}),
    "I6": ("line", ["mes", "tipo"], ["propina_pct_tarifa"], {}),
    "I7": ("bar", ["borough", "anio"], ["pct_viajes"], {}),
    "I8": ("line", ["hora", "anio"], ["velocidad_mediana_mph"], {}),
    "I9": ("bar", ["anio"], ["pct_viajes", "pct_ingresos"], {}),
    "I10": ("line", ["mes"], ["pct_excluidos", "pct_sin_info_pago"], {}),
}


def api(sesion: requests.Session, metodo: str, ruta: str, **kwargs):
    respuesta = sesion.request(metodo, f"{URL}/api/{ruta}", timeout=120, **kwargs)
    respuesta.raise_for_status()
    return respuesta.json() if respuesta.content else None


def main() -> int:
    sesion = requests.Session()

    propiedades = api(sesion, "GET", "session/properties")
    if not propiedades.get("has-user-setup"):
        api(sesion, "POST", "setup", json={
            "token": propiedades["setup-token"],
            "user": {"email": EMAIL, "password": PASSWORD,
                     "first_name": "Lab", "last_name": "8", "site_name": "Lab 8 DuckDB"},
            "prefs": {"site_name": "Lab 8 DuckDB", "allow_tracking": False},
        })
        print("Metabase configurado")

    token = api(sesion, "POST", "session", json={"username": EMAIL, "password": PASSWORD})["id"]
    sesion.headers["X-Metabase-Session"] = token

    if any(t["name"] == NOMBRE_TABLERO for t in api(sesion, "GET", "dashboard")):
        print(f"El tablero '{NOMBRE_TABLERO}' ya existe; no se crea de nuevo")
        return 0

    bases = api(sesion, "GET", "database")["data"]
    db_id = next((b["id"] for b in bases if b["name"] == NOMBRE_DB), None)
    if db_id is None:
        db_id = api(sesion, "POST", "database", json={
            "engine": "duckdb", "name": NOMBRE_DB,
            "details": {"database_file": "/workspace/data/processed/taxis.duckdb", "read_only": True},
        })["id"]

    sql = (RAIZ_PROYECTO / "sql" / "ex7_indicadores.sql").read_text(encoding="utf-8")
    tablero = api(sesion, "POST", "dashboard", json={"name": NOMBRE_TABLERO})
    tarjetas = []
    for i, (titulo, consulta) in enumerate(dividir_bloques(sql)[1]):
        grafico, dimensiones, metricas, extra = GRAFICOS[titulo.split()[0]]
        tarjeta = api(sesion, "POST", "card", json={
            "name": titulo,
            "display": grafico,
            "dataset_query": {"type": "native", "database": db_id,
                              "native": {"query": consulta.rstrip(";")}},
            "visualization_settings": {"graph.dimensions": dimensiones,
                                       "graph.metrics": metricas, **extra},
        })
        tarjetas.append({"id": -(i + 1), "card_id": tarjeta["id"],
                         "row": (i // 2) * 7, "col": (i % 2) * 12, "size_x": 12, "size_y": 7})
        print(f"  {titulo}")

    api(sesion, "PUT", f"dashboard/{tablero['id']}", json={"dashcards": tarjetas})
    print(f"Tablero creado: {URL}/dashboard/{tablero['id']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
