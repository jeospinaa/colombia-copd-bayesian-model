#!/bin/bash
# Script para instalar dependencias espaciales necesarias para la Figura 1

echo "═══════════════════════════════════════════════════════════════"
echo "  INSTALACIÓN DE DEPENDENCIAS PARA FIGURAS ESPACIALES"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Actualizar repositorios
echo "1. Actualizando repositorios..."
sudo apt-get update

# Instalar dependencias del sistema
echo ""
echo "2. Instalando dependencias del sistema..."
sudo apt-get install -y \
  libgdal-dev \
  libproj-dev \
  libgeos-dev \
  libudunits2-dev \
  cmake \
  libabsl-dev

# Verificar instalación
echo ""
echo "3. Verificando instalación..."
if command -v cmake &> /dev/null; then
    echo "   ✓ cmake instalado"
    cmake --version | head -1
else
    echo "   ✗ cmake no encontrado"
fi

# Instalar paquetes R
echo ""
echo "4. Instalando paquetes R..."
Rscript -e "install.packages(c('sf', 's2', 'rnaturalearth', 'rnaturalearthdata'), repos='https://cloud.r-project.org')"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  INSTALACIÓN COMPLETA"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Para verificar, ejecuta:"
echo "  Rscript -e \"library(sf); library(rnaturalearth); cat('✓ Paquetes instalados correctamente\n')\""
echo ""
echo "Luego ejecuta el script de figuras:"
echo "  Rscript analysis/04_manuscript_figures_high_res.R"

