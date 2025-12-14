# Instalación de Paquetes Espaciales para Figura 1

## Problema

Los paquetes `sf` y `rnaturalearth` requieren dependencias del sistema que no están instaladas por defecto.

## Solución: Instalar Dependencias del Sistema

Ejecuta los siguientes comandos en tu terminal:

```bash
# Actualizar repositorios
sudo apt-get update

# Instalar dependencias del sistema
sudo apt-get install -y \
  libgdal-dev \
  libproj-dev \
  libgeos-dev \
  libudunits2-dev \
  cmake \
  libabsl-dev
```

## Luego Instalar Paquetes R

Una vez instaladas las dependencias del sistema, ejecuta en R:

```r
install.packages(c("sf", "s2", "rnaturalearth", "rnaturalearthdata"))
```

## Alternativa: Paquetes Precompilados

Si prefieres usar paquetes R precompilados (más rápido pero pueden estar desactualizados):

```bash
sudo apt-get install -y r-cran-sf r-cran-s2 r-cran-rnaturalearth
```

## Verificación

Después de la instalación, verifica que todo funciona:

```r
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)

# Probar carga de datos
colombia <- ne_states(country = "colombia", returnclass = "sf")
print("✓ Paquetes espaciales funcionando correctamente")
```

## Nota

Las Figuras 2 y 3 ya están generadas y no requieren estos paquetes. Solo la Figura 1 (mapas) requiere las dependencias espaciales.

