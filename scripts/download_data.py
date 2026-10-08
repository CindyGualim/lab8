#!/usr/bin/env python3
"""Descarga los archivos Parquet del NYC TLC Trip Record Data.

Descarga los registros de viajes de taxis amarillos (yellow) y verdes (green)
para los anios configurados en ANIOS (por defecto 2024, 2025 y 2026; 2026 fue el
conjunto inicial, 2024 se agrego en el Ejercicio 5 y 2025 en el Ejercicio 8). Tambien pueden indicarse con --anio.

Fuente oficial de los datos:
    https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

Uso:
    python scripts/download_data.py                       # anios de ANIOS, ambos tipos
    python scripts/download_data.py --taxi yellow
    python scripts/download_data.py --anio 2026 2024      # anios especificos
    python scripts/download_data.py --verificar           # solo verifica, no descarga

Los archivos se guardan en:
    data/raw/<tipo>/<anio>/<nombre-original>.parquet

Comportamiento:
  - La TLC publica cada mes con varias semanas de atraso, por lo que no todos
    los meses del anio en curso existen todavia. El script consulta al servidor
    que meses estan publicados en lugar de suponerlos.
  - Un archivo que ya existe localmente no se vuelve a descargar.
  - La descarga se hace sobre un nombre temporal y solo se renombra al
    terminar, de modo que una interrupcion no deja archivos .parquet a medias.
  - Al terminar cada descarga se compara el tamanio con el Content-Length del
    servidor y se valida la firma Parquet ("PAR1" al inicio y al final).
  - --verificar compara cada archivo local contra el servidor (tamanio y firma)
    y reporta los meses publicados que faltan localmente.
  - Tambien descarga la tabla de zonas de la TLC (data/raw/taxi_zone_lookup.csv),
    que traduce PULocationID / DOLocationID a borough y zona.
"""

import argparse
import sys
from pathlib import Path

import requests

# Anios que se descargan cuando no se usa --anio. Para incorporar un anio nuevo
# basta con agregarlo aqui (o pasarlo por linea de comandos).
ANIOS = (2024, 2025, 2026)
TIPOS_TAXI = ("yellow", "green")
URL_BASE = "https://d37ci6vzurychx.cloudfront.net/trip-data"
URL_ZONAS = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

# Ruta absoluta a partir de la ubicacion del script: funciona igual desde la
# raiz del proyecto, desde scripts/ o dentro del contenedor (/workspace).
RAIZ_PROYECTO = Path(__file__).resolve().parent.parent
DIR_DESTINO = RAIZ_PROYECTO / "data" / "raw"

TIEMPO_ESPERA = 60          # segundos por peticion
INTENTOS = 3                # intentos por archivo antes de darse por vencido
BLOQUE = 1024 * 1024        # 1 MiB por bloque de descarga
SUFIJO_TEMPORAL = ".part"
FIRMA_PARQUET = b"PAR1"


def construir_nombre(tipo: str, anio: int, mes: int) -> str:
    """Nombre del archivo publicado por la TLC, p. ej. yellow_tripdata_2026-01.parquet."""
    return f"{tipo}_tripdata_{anio}-{mes:02d}.parquet"


def construir_url(tipo: str, anio: int, mes: int) -> str:
    """URL completa del archivo Parquet mensual."""
    return f"{URL_BASE}/{construir_nombre(tipo, anio, mes)}"


def ruta_destino(tipo: str, anio: int, mes: int) -> Path:
    """Ruta local donde se guarda el archivo."""
    return DIR_DESTINO / tipo / str(anio) / construir_nombre(tipo, anio, mes)


def tamanio_publicado(url: str) -> int | None:
    """Tamanio en bytes del archivo en el servidor, o None si no esta publicado.

    Devuelve -1 si el archivo existe pero el servidor no informa su tamanio.
    """
    try:
        respuesta = requests.head(url, timeout=TIEMPO_ESPERA, allow_redirects=True)
    except requests.RequestException:
        return None
    if not respuesta.ok:
        return None
    return int(respuesta.headers.get("Content-Length", -1))


def es_parquet_valido(ruta: Path) -> bool:
    """Comprueba la firma 'PAR1' al inicio y al final del archivo."""
    if ruta.stat().st_size < 2 * len(FIRMA_PARQUET):
        return False
    with ruta.open("rb") as archivo:
        inicio = archivo.read(len(FIRMA_PARQUET))
        archivo.seek(-len(FIRMA_PARQUET), 2)
        fin = archivo.read(len(FIRMA_PARQUET))
    return inicio == FIRMA_PARQUET and fin == FIRMA_PARQUET


def formato_tamanio(n: float) -> str:
    for unidad in ("B", "KiB", "MiB", "GiB"):
        if n < 1024 or unidad == "GiB":
            return f"{n:.1f} {unidad}"
        n /= 1024
    return f"{n:.1f} GiB"


def descargar_archivo(url: str, destino: Path, esperado: int) -> int:
    """Descarga `url` en `destino`. Devuelve la cantidad de bytes escritos."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    temporal = destino.with_name(destino.name + SUFIJO_TEMPORAL)

    ultimo_error = None
    for intento in range(1, INTENTOS + 1):
        try:
            with requests.get(url, stream=True, timeout=TIEMPO_ESPERA) as respuesta:
                respuesta.raise_for_status()
                escritos = 0
                with temporal.open("wb") as archivo:
                    for bloque in respuesta.iter_content(chunk_size=BLOQUE):
                        if bloque:
                            archivo.write(bloque)
                            escritos += len(bloque)
            if escritos == 0:
                raise requests.RequestException("el servidor devolvio un archivo vacio")
            if esperado >= 0 and escritos != esperado:
                raise requests.RequestException(
                    f"descarga incompleta: {escritos} de {esperado} bytes"
                )
            if not es_parquet_valido(temporal):
                raise requests.RequestException("el archivo no tiene la firma Parquet")
            temporal.replace(destino)
            return escritos
        except requests.RequestException as error:
            ultimo_error = error
            temporal.unlink(missing_ok=True)
            if intento < INTENTOS:
                print(f"      intento {intento}/{INTENTOS} fallido ({error}); reintentando")

    raise requests.RequestException(f"no se pudo descargar {url}: {ultimo_error}")


def descargar_zonas() -> None:
    """Descarga la tabla de zonas de la TLC si no existe localmente."""
    destino = DIR_DESTINO / "taxi_zone_lookup.csv"
    if destino.exists() and destino.stat().st_size > 0:
        print(f"\nZonas: {destino.relative_to(RAIZ_PROYECTO).as_posix()} ya existe, se omite")
        return
    try:
        respuesta = requests.get(URL_ZONAS, timeout=TIEMPO_ESPERA)
        respuesta.raise_for_status()
    except requests.RequestException as error:
        print(f"\nZonas: ERROR al descargar {URL_ZONAS}: {error}")
        return
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_bytes(respuesta.content)
    print(f"\nZonas: listo -> {destino.relative_to(RAIZ_PROYECTO).as_posix()}")


def resumen_vacio() -> dict:
    return {"descargados": 0, "omitidos": 0, "no_publicados": [], "fallidos": []}


def descargar(tipo: str, anio: int) -> dict:
    """Descarga todos los meses publicados de un tipo de taxi para un anio."""
    print(f"\n=== {tipo.upper()} {anio} ===")
    resumen = resumen_vacio()

    for mes in range(1, 13):
        etiqueta = f"{anio}-{mes:02d}"
        destino = ruta_destino(tipo, anio, mes)

        if destino.exists() and destino.stat().st_size > 0:
            print(f"  {etiqueta}  ya existe, se omite")
            resumen["omitidos"] += 1
            continue

        url = construir_url(tipo, anio, mes)
        esperado = tamanio_publicado(url)
        if esperado is None:
            print(f"  {etiqueta}  aun no publicado por la TLC")
            resumen["no_publicados"].append(etiqueta)
            continue

        print(f"  {etiqueta}  descargando ({formato_tamanio(max(esperado, 0))})...")
        try:
            escritos = descargar_archivo(url, destino, esperado)
        except requests.RequestException as error:
            print(f"  {etiqueta}  ERROR: {error}")
            resumen["fallidos"].append(etiqueta)
        else:
            print(f"  {etiqueta}  listo ({formato_tamanio(escritos)}) -> "
                  f"{destino.relative_to(RAIZ_PROYECTO)}")
            resumen["descargados"] += 1

    return resumen


def verificar(tipos: tuple, anios: tuple) -> int:
    """Compara los archivos locales con lo publicado por la TLC.

    Para cada mes de cada anio y tipo:
      OK         existe localmente, mismo tamanio que el servidor y firma Parquet valida
      FALTA      publicado en el servidor pero no existe localmente
      DIFERENTE  existe localmente pero el tamanio no coincide o la firma es invalida
      ---        no publicado por la TLC (y no existe localmente)
    """
    problemas = 0
    total_ok = 0
    total_bytes = 0
    print(f"{'archivo':<36} {'local':>12} {'servidor':>12}  estado")
    print("-" * 72)
    for tipo in tipos:
        for anio in anios:
            for mes in range(1, 13):
                destino = ruta_destino(tipo, anio, mes)
                remoto = tamanio_publicado(construir_url(tipo, anio, mes))
                local = destino.stat().st_size if destino.exists() else None

                if local is None and remoto is None:
                    estado = "---"
                elif local is None:
                    estado = "FALTA"
                elif (remoto is not None and remoto >= 0 and local != remoto) \
                        or not es_parquet_valido(destino):
                    estado = "DIFERENTE"
                else:
                    estado = "OK"

                if estado in ("FALTA", "DIFERENTE"):
                    problemas += 1
                if estado == "OK":
                    total_ok += 1
                    total_bytes += local

                print(f"{destino.name:<36} "
                      f"{'-' if local is None else local:>12} "
                      f"{'-' if remoto is None else remoto:>12}  {estado}")
    print("-" * 72)
    print(f"archivos OK: {total_ok} ({formato_tamanio(total_bytes)}), "
          f"con problemas: {problemas}")
    return 1 if problemas else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Descarga los datos de taxis amarillos y verdes del NYC TLC."
    )
    parser.add_argument(
        "--taxi", choices=(*TIPOS_TAXI, "all"), default="all",
        help="tipo de taxi a descargar (por defecto: all)",
    )
    parser.add_argument(
        "--anio", type=int, nargs="+", default=list(ANIOS),
        help=f"anio(s) a descargar (por defecto: {' '.join(map(str, ANIOS))})",
    )
    parser.add_argument(
        "--verificar", action="store_true",
        help="no descarga; compara los archivos locales con los publicados",
    )
    argumentos = parser.parse_args()

    tipos = TIPOS_TAXI if argumentos.taxi == "all" else (argumentos.taxi,)
    anios = tuple(sorted(set(argumentos.anio)))

    if argumentos.verificar:
        return verificar(tipos, anios)

    descargar_zonas()

    total = resumen_vacio()
    for tipo in tipos:
        for anio in anios:
            resumen = descargar(tipo, anio)
            total["descargados"] += resumen["descargados"]
            total["omitidos"] += resumen["omitidos"]
            total["no_publicados"] += [f"{tipo} {m}" for m in resumen["no_publicados"]]
            total["fallidos"] += [f"{tipo} {m}" for m in resumen["fallidos"]]

    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    print(f"  descargados   : {total['descargados']}")
    print(f"  ya existian   : {total['omitidos']}")
    print(f"  no publicados : {len(total['no_publicados'])}")
    if total["no_publicados"]:
        print(f"      {', '.join(total['no_publicados'])}")
    print(f"  fallidos      : {len(total['fallidos'])}")
    if total["fallidos"]:
        print(f"      {', '.join(total['fallidos'])}")
    print("=" * 60)

    return 1 if total["fallidos"] else 0


if __name__ == "__main__":
    sys.exit(main())
