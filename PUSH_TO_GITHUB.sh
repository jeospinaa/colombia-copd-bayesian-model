#!/bin/bash
# Script para subir el repositorio a GitHub
# Ejecutar después de crear el repositorio en GitHub

echo "═══════════════════════════════════════════════════════════════"
echo "  SUBIR REPOSITORIO A GITHUB"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d ".git" ]; then
    echo "✗ Error: No se encontró un repositorio git"
    echo "  Ejecuta primero: git init"
    exit 1
fi

# Solicitar información del usuario
read -p "Ingresa tu usuario de GitHub: " GITHUB_USER
read -p "Ingresa el nombre del repositorio (default: copd-colombia-prevalence): " REPO_NAME
REPO_NAME=${REPO_NAME:-copd-colombia-prevalence}

echo ""
echo "Configurando remote..."
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo "✓ Remote configurado: https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
echo ""

# Verificar si el repositorio existe en GitHub
echo "Verificando conexión..."
if git ls-remote --heads origin main &>/dev/null || git ls-remote --heads origin master &>/dev/null; then
    echo "✓ Repositorio encontrado en GitHub"
else
    echo "⚠ El repositorio no existe en GitHub aún"
    echo ""
    echo "Por favor crea el repositorio en GitHub primero:"
    echo "  1. Ve a https://github.com/new"
    echo "  2. Nombre: ${REPO_NAME}"
    echo "  3. Descripción: Bayesian epidemiological analysis estimating COPD prevalence in Colombia"
    echo "  4. Visibilidad: Public"
    echo "  5. NO marques 'Initialize with README'"
    echo "  6. Haz clic en 'Create repository'"
    echo ""
    read -p "Presiona Enter cuando hayas creado el repositorio..."
fi

echo ""
echo "Subiendo código a GitHub..."
echo ""

# Cambiar a rama main si estamos en master
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "master" ]; then
    git branch -M main
    echo "✓ Rama renombrada a 'main'"
fi

# Hacer push
echo "Ejecutando: git push -u origin main"
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  ✓ REPOSITORIO SUBIDO EXITOSAMENTE"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Tu repositorio está disponible en:"
    echo "  https://github.com/${GITHUB_USER}/${REPO_NAME}"
    echo ""
else
    echo ""
    echo "✗ Error al subir el repositorio"
    echo "  Verifica:"
    echo "    - Que el repositorio existe en GitHub"
    echo "    - Tus credenciales de GitHub"
    echo "    - Tu conexión a internet"
    echo ""
    echo "Si el problema es con archivos grandes (models/final_model.rds),"
    echo "considera usar Git LFS o mover el modelo a releases."
fi

