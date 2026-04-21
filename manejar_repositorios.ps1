param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivoAlumnos
)

# =========================
# CONFIGURACION DEL REPOSITORIO
# $RepoUrl = "https://github.com/fbinche/Desarrollo-Web-I.02.2026-IIA-Ate.git"
# =========================
$RepoUrl = "https://github.com/Tilusiono/Desarrollo-Web.git"
$NombreProyecto = [System.IO.Path]::GetFileNameWithoutExtension($RepoUrl)

# =========================
# CARPETA BASE
# =========================
$carpetaBase = "configuracion-github"

if (!(Test-Path $carpetaBase)) {
    Write-Host "No existe la carpeta $carpetaBase"
    exit
}

# =========================
# OBTENER CARPETAS EXISTENTES
# =========================
$carpetas = Get-ChildItem $carpetaBase -Directory

foreach ($carpeta in $carpetas) {

    $rama = $carpeta.Name
    $carpetaAlumno = $carpeta.FullName

    Write-Host "Generando scripts para: $rama"

    # ==========================================================
    # 0️⃣ ABRIR REPO EN VS CODE
    # ==========================================================
    $rutaAbrirVSC = Join-Path $carpetaAlumno "GITHUB_0_abrir_repo_vsc.bat"

    $contenidoAbrirVSC = @"
    @echo off

    set RAMA=$rama
    set PROYECTO=C:\Repositorios\%RAMA%\$NombreProyecto

    if not exist "%PROYECTO%" (
        echo El proyecto no existe en la ruta esperada.
        echo Primero debes clonar el repositorio.
        pause
        exit
    )

    cd /d "%PROYECTO%"

    code .

    if %errorlevel% neq 0 (
        echo No se pudo abrir Visual Studio Code.
        echo Verifica que el comando "code" este disponible en tu sistema.
        pause
        exit
    )

    echo Proyecto abierto en Visual Studio Code.
    pause
"@

    Set-Content -Path $rutaAbrirVSC -Value $contenidoAbrirVSC -Encoding ASCII


    # ==========================================================
    # 1️⃣ CLONAR RAMA
    # ==========================================================
    $rutaClonar = Join-Path $carpetaAlumno "GITHUB_1_clonar_rama.bat"

    $contenidoClonar = @"
@echo off

set RAMA=$rama
set BASE=C:\Repositorios\%RAMA%
set PROYECTO=%BASE%\$NombreProyecto

if not exist "%BASE%" mkdir "%BASE%"

cd /d "%BASE%"

if exist "%PROYECTO%\.git" (
    echo El repositorio ya esta clonado.
    pause
    exit
)

git clone -b %RAMA% --single-branch $RepoUrl

if %errorlevel% neq 0 (
    echo Error al clonar.
    pause
    exit
)

echo Rama clonada correctamente.
pause
"@

    Set-Content -Path $rutaClonar -Value $contenidoClonar -Encoding ASCII

    # ==========================================================
    # 2️⃣ BAJAR CAMBIOS
    # ==========================================================
    $rutaPull = Join-Path $carpetaAlumno "GITHUB_2_bajar_cambios.bat"

    $contenidoPull = @"
@echo off

set RAMA=$rama
set PROYECTO=C:\Repositorios\%RAMA%\$NombreProyecto

if not exist "%PROYECTO%\.git" (
    echo El proyecto no esta clonado.
    pause
    exit
)

cd /d "%PROYECTO%"

git checkout %RAMA%
git pull origin %RAMA%

echo Rama actualizada correctamente.
pause
"@

    Set-Content -Path $rutaPull -Value $contenidoPull -Encoding ASCII

    # ==========================================================
    # 3️⃣ SUBIR CAMBIOS
    # ==========================================================
    $rutaPush = Join-Path $carpetaAlumno "GITHUB_3_subir_cambios.bat"

    $contenidoPush = @"
@echo off

set RAMA=$rama
set PROYECTO=C:\Repositorios\%RAMA%\$NombreProyecto

if not exist "%PROYECTO%\.git" (
    echo El repositorio no esta clonado.
    pause
    exit
)

cd /d "%PROYECTO%"

git checkout %RAMA%
git pull origin %RAMA%

for /f %%i in ('powershell -command "Get-Date -Format MM-dd-yyyy_HH-mm"') do set FECHA=%%i

git add .

git commit -m "Cambio %RAMA% %FECHA%"

git push origin %RAMA%

if %errorlevel% neq 0 (
    echo Error al hacer push.
    pause
    exit
)

echo Cambios subidos correctamente.
pause
"@

    Set-Content -Path $rutaPush -Value $contenidoPush -Encoding ASCII
}

Write-Host "Scripts generados en todas las carpetas existentes."