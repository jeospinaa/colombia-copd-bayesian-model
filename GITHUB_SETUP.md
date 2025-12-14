# Instrucciones para Subir el Repositorio a GitHub

## Paso 1: Crear el Repositorio en GitHub

1. Ve a https://github.com y inicia sesión
2. Haz clic en el botón "+" (arriba a la derecha) → "New repository"
3. Nombre del repositorio: `copd-colombia-prevalence` (o el que prefieras)
4. Descripción: "Bayesian epidemiological analysis estimating COPD prevalence in Colombia accounting for diagnostic access"
5. Visibilidad: **Public** (para ciencia abierta)
6. NO marques "Initialize with README" (ya tenemos uno)
7. Haz clic en "Create repository"

## Paso 2: Conectar y Subir

Una vez creado el repositorio en GitHub, ejecuta estos comandos:

```bash
cd "/home/jorge/Documentos/GoogleDrive/1ANextmove2024/1A_EPOC/4. Cursor"

# Agregar el remote (reemplaza USERNAME con tu usuario de GitHub)
git remote add origin https://github.com/USERNAME/copd-colombia-prevalence.git

# O si prefieres SSH:
# git remote add origin git@github.com:USERNAME/copd-colombia-prevalence.git

# Verificar el remote
git remote -v

# Subir el código
git branch -M main
git push -u origin main
```

## Paso 3: Verificar

Después del push, verifica que todo esté en GitHub:
- README.md se muestra correctamente
- Todos los archivos están presentes
- Los badges funcionan

## Nota sobre Archivos Grandes

El archivo `models/final_model.rds` puede ser grande. Si GitHub rechaza el push:
- Considera usar Git LFS: `git lfs track "*.rds"`
- O mueve el modelo a releases de GitHub

