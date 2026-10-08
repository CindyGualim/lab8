# Ejercicio 9 – Discusión

## 9.1 ¿Qué características de DuckDB resultaron más útiles?

Poder leer Parquet directamente con `read_parquet` y patrones como `data/raw/yellow/*/*.parquet`, sin ningún paso de carga. También `union_by_name`, que permitió juntar archivos con columnas distintas (`cbd_congestion_fee` desde 2025 y `request_source` desde 2026-06), y `filename = true`, que nos dio el mes y el año de cada registro a partir de la ruta. Las funciones `parquet_file_metadata` y `parquet_schema` sirvieron para validar las descargas en milisegundos sin leer las filas. Por último, que todo corre en el mismo proceso de Python y que la misma base se pudo abrir desde Metabase en modo de solo lectura.

## 9.2 Ventajas y limitaciones de consultar directamente Parquet

Ventajas: no hay que cargar ni actualizar nada; un archivo nuevo se puede consultar apenas se descarga, y ocupa la mitad del espacio que la tabla DuckDB (1 977 MiB contra 4 210 MiB con los tres años). DuckDB solo lee las columnas que usa la consulta y los metadatos permiten contar registros sin leer los datos.

Limitaciones: cada consulta vuelve a leer y transformar los archivos, por lo que en el benchmark fue entre 1.5 y 62 veces más lenta que la tabla. Las reglas de calidad y las columnas calculadas de la vista se recalculan cada vez. Además depende de la velocidad del disco: en este ambiente los archivos están en una carpeta de Windows montada en Docker, lo que hace la lectura más lenta. Con los tres años, algunas consultas pesadas fallaron por memoria al leer los archivos (ver Ejercicio 8).

## 9.3 Ventajas y limitaciones de las tablas materializadas

Ventajas: las consultas son mucho más rápidas, sobre todo los conteos, agrupaciones y filtros por fecha, porque los datos ya están transformados y DuckDB usa estadísticas por bloque para saltarse lo que no necesita. Es la mejor opción para un tablero que se consulta muchas veces, como el de Metabase.

Limitaciones: crear la tabla tarda (135 s con 121 millones de registros), ocupa más espacio en disco, y queda desactualizada cuando llegan archivos nuevos, así que hay que reconstruirla. Además el archivo `.duckdb` solo admite un proceso con escritura, por lo que para reconstruirla hubo que detener Metabase. Las consultas con medianas siguen siendo lentas en la tabla porque el costo está en el cálculo y no en la lectura.

## 9.4 Ventajas frente a cargar todo con Pandas

Con Pandas habría que cargar en memoria los 121 millones de registros de los tres años, que ocupan mucho más que los 7.4 GB del contenedor. DuckDB procesa los datos por bloques, lee solo las columnas necesarias, usa todos los núcleos y puede usar disco cuando no alcanza la memoria. También permite escribir el análisis en SQL, que queda versionado en archivos y se ejecuta igual desde un script, un notebook o Metabase. Pandas se usó solo al final, para recibir resultados pequeños ya agregados y graficarlos.

## 9.5 ¿Qué características permiten incorporar datos con cambios mínimos?

Los años se configuran en una sola constante del script de descarga (`ANIOS`), que además omite los archivos que ya existen. Los archivos se guardan en `data/raw/<tipo>/<año>/`, y todas las consultas usan patrones sobre esa estructura en vez de nombres de archivo. La normalización está en una sola vista (`viajes`) y los indicadores agrupan por mes o por año sin fijar ningún año. Por eso agregar 2025 requirió cambiar una línea, volver a descargar y reconstruir la base.

## 9.6 ¿Qué se debería automatizar en producción?

La descarga mensual de los archivos nuevos (por ejemplo con una tarea programada), la verificación que ya hace `--verificar`, la reconstrucción de la tabla DuckDB (idealmente agregando solo el mes nuevo en vez de reconstruir todo) y la ejecución de las consultas de validación con alertas si falta un mes o si sube mucho el porcentaje de registros excluidos o sin información de pago, como pasó en 2026.

## 9.7 Decisiones de diseño importantes para la reproducibilidad

Usar Docker con versiones fijas de DuckDB y de las demás librerías, y la misma versión de DuckDB en el driver de Metabase. Mantener los datos fuera de Git pero con un script que los vuelve a descargar desde la fuente original y los valida. Guardar todas las consultas en archivos `.sql` que se ejecutan con un script y que guardan su resultado y su tiempo en `docs/resultados/`. Crear el tablero con un script en lugar de hacerlo a mano en Metabase. Y usar rutas relativas a la raíz del proyecto, para que todo funcione igual dentro y fuera del contenedor.

## 9.8 ¿Qué se aprendió que no habría sido evidente con datos pequeños?

Que el formato y el lugar donde se guardan los datos cambian mucho el tiempo de respuesta: con tres años el mismo filtro por fecha pasó de 1.25 s a 0.02 s solo por usar la tabla. Que la memoria se vuelve un límite real: consultas que funcionaban con dos años fallaron con tres porque las medianas y los `DISTINCT` necesitan guardar todos los valores. Que los problemas de calidad cambian con el tiempo (los registros sin forma de pago pasaron de 9 % a 20 % y a 25 %, y los montos negativos subieron a 5 % solo en 2025) y solo se notan al comparar varios años. Y que los esquemas de los archivos cambian (columnas nuevas en 2025 y 2026), por lo que el proceso tiene que tolerarlo desde el diseño.
