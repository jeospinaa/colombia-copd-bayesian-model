#!/bin/bash
# Script para hacer push con autenticación

echo "═══════════════════════════════════════════════════════════════"
echo "  SUBIR REPOSITORIO A GITHUB"
echo "═══════════════════════════════════════════════════════════════"
echo ""

cd "/home/jorge/Documentos/GoogleDrive/1ANextmove2024/1A_EPOC/4. Cursor"

# Verificar remote
echo "Remote configurado:"
git remote -v
echo ""

# Opción 1: Intentar con SSH
echo "Intentando con SSH..."
git remote set-url origin git@github.com:jeospinaa/colombia-copd-bayesian-model.git
git push -u origin main 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ ¡Repositorio subido exitosamente!"
    echo "  https://github.com/jeospinaa/colombia-copd-bayesian-model"
    exit 0
fi

# Si SSH falla, usar HTTPS con token
echo ""
echo "SSH no disponible. Usando HTTPS..."
echo "Necesitarás un Personal Access Token de GitHub"
echo ""
echo "Para crear un token:"
echo "  1. Ve a: https://github.com/settings/tokens"
echo "  2. Generate new token (classic)"
echo "  3. Selecciona scope: 'repo'"
echo "  4. Copia el token"
echo ""
read -p "Presiona Enter cuando tengas el token listo..."

git remote set-url origin https://github.com/jeospinaa/colombia-copd-bayesian-model.git
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ ¡Repositorio subido exitosamente!"
    echo "  https://github.com/jeospinaa/colombia-copd-bayesian-model"
else
    echo ""
    echo "✗ Error al subir. Verifica:"
    echo "  - Tu token de acceso personal"
    echo "  - Tu conexión a internet"
    echo "  - Que el repositorio existe en GitHub"
fi
