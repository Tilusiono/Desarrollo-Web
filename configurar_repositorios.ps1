param(
    [string]$archivo
)

if (-not $archivo) {
    Write-Host "Debe indicar el archivo. Ejemplo:"
    Write-Host ".\configurar_repositorios.ps1 alumnos.txt"
    exit
}

if (!(Test-Path ".\$archivo")) {
    Write-Host "No se encontro $archivo en esta carpeta."
    exit
}

$lineas = Get-Content ".\$archivo" | Select-Object -Skip 1

if ($lineas.Count -eq 0) {
    Write-Host "El archivo no tiene registros."
    exit
}

$carpetaBase = "configuracion-github"

if (!(Test-Path $carpetaBase)) {
    New-Item -ItemType Directory -Path $carpetaBase | Out-Null
}

function To-ProperCase($texto) {
    return ($texto.ToLower().Split(" ") | ForEach-Object {
            if ($_ -ne "") {
                $_.Substring(0, 1).ToUpper() + $_.Substring(1)
            }
        }) -join " "
}

foreach ($linea in $lineas) {

    $campos = $linea -split "`t"

    if ($campos.Count -lt 5) {
        $campos = $linea -split "\s{2,}"
    }

    if ($campos.Count -lt 5) {
        Write-Host "Linea ignorada: $linea"
        continue
    }

    $apellidos = $campos[2]
    $nombres = $campos[3]
    $correo = $campos[4]
    $primerNombre = $nombres.Split(" ")[0]
    $primerApellido = $apellidos.Split(" ")[0]
    $rama = ($primerNombre + "-" + $primerApellido).ToLower()

    if ([string]::IsNullOrWhiteSpace($rama)) {
        continue
    }

    Write-Host "Generando estructura para: $rama"

    $carpetaAlumno = Join-Path $carpetaBase $rama

    if (!(Test-Path $carpetaAlumno)) {
        New-Item -ItemType Directory -Path $carpetaAlumno | Out-Null
    }

    #1 GENERAR CLAVE + MOSTRAR/COPIAR CLAVE PÚBLICA
    $rutaGenerar = Join-Path $carpetaAlumno "1_generar_llave_shh.bat"
    Set-Content $rutaGenerar @"
    @echo off
    cd /d %~dp0

    if not exist key_$rama (
        ssh-keygen -t ed25519 -C "$correo" -f key_$rama -N ""
    )

    if not exist key_$rama.pub (
        echo No se pudo generar la clave publica.
        pause
        exit
    )

    echo.
    echo ===== CLAVE PUBLICA =====
    type key_$rama.pub
    echo.
    type key_$rama.pub | clip
    echo La clave publica fue copiada al portapapeles.
    pause
"@ -Encoding ASCII

    # 2 INSTALAR KEY + AGREGAR CONFIG SSH
    $rutaInstalarSSH = Join-Path $carpetaAlumno "2_instalacion&validacion_llave_ssh.bat"
    Set-Content $rutaInstalarSSH @"
    @echo off
    cd /d %~dp0

    set SSHDIR=%USERPROFILE%\.ssh
    set CONFIGFILE=%SSHDIR%\config

    if not exist "%SSHDIR%" (
        mkdir "%SSHDIR%"
    )

    if not exist key_$rama (
        echo No se encontro la clave privada key_$rama
        pause
        exit
    )

    if not exist key_$rama.pub (
        echo No se encontro la clave publica key_$rama.pub
        pause
        exit
    )

    copy /Y key_$rama "%SSHDIR%\key_$rama" >nul
    copy /Y key_$rama.pub "%SSHDIR%\key_$rama.pub" >nul

    echo.>> "%CONFIGFILE%"
    echo Host github-$rama>> "%CONFIGFILE%"
    echo     HostName github.com>> "%CONFIGFILE%"
    echo     User git>> "%CONFIGFILE%"
    echo     IdentityFile ~/.ssh/key_$rama>> "%CONFIGFILE%"

    echo Claves copiadas a %SSHDIR%
    echo Configuracion SSH agregada a %CONFIGFILE%
    echo.
    echo Probando conexion con GitHub...
    ssh -T github-$rama
    pause
"@ -Encoding ASCII

    #3 INCLUDE EN .GITCONFIG
    $rutaInclude = Join-Path $carpetaAlumno "3_configurar_gitconfig.bat"
    Set-Content $rutaInclude @"
    @echo off

    set GITCONFIG=%USERPROFILE%\.gitconfig

    REM Si no existe .gitconfig lo crea
    if not exist "%GITCONFIG%" (
        type nul > "%GITCONFIG%"
    )

    REM Validar si ya existe el include
    findstr /C:"gitdir:C:/Repositorios/$rama/" "%GITCONFIG%" >nul

    if %errorlevel%==0 (
        echo El include para $rama ya existe en %GITCONFIG%
        pause
        exit
    )

    REM Si no existe, lo agrega
    echo.>> "%GITCONFIG%"
    echo [includeIf "gitdir:C:/Repositorios/$rama/"]>> "%GITCONFIG%"
    echo     path = C:/Repositorios/.gitconfig-$rama>> "%GITCONFIG%"

    echo Include agregado correctamente en %GITCONFIG%
    pause
"@ -Encoding ASCII


    #GENERAR ARCHIVO .GITCONFIG-RAMA 
    $rutaGitconfig = Join-Path $carpetaAlumno ".gitconfig-$rama"
    $nombreCompleto = To-ProperCase "$nombres $apellidos"

    Set-Content $rutaGitconfig @"
[user]
    name = $nombreCompleto
    email = $correo
"@ -Encoding ASCII


    #4 INSTALAR GITCONFIG-RAMA
    $rutaInstalar = Join-Path $carpetaAlumno "4_instalar_gitconfig-$rama.bat"
    Set-Content $rutaInstalar @"
@echo off
set RAMA=$rama
set DESTINO=C:\Repositorios
set CARPETA=%DESTINO%\%RAMA%
set ARCHIVO=.gitconfig-%RAMA%

if not exist "%CARPETA%" mkdir "%CARPETA%"
if not exist "%ARCHIVO%" (
    echo No se encontro %ARCHIVO%
    pause
    exit
)

move /Y "%ARCHIVO%" "%DESTINO%\%ARCHIVO%"
pause
"@ -Encoding ASCII
}

Write-Host "Proceso completado correctamente."