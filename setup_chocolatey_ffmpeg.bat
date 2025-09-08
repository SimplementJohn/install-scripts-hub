@echo off
setlocal enabledelayedexpansion

echo ====================================
echo Installation de Chocolatey et FFmpeg
echo ====================================
echo.

REM Vérification des privilèges administrateur
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo ERREUR: Ce script doit être exécuté en tant qu'administrateur.
    echo Clic droit sur le fichier et "Exécuter en tant qu'administrateur"
    pause
    exit /b 1
)

REM Installation de Chocolatey
echo [1/3] Installation de Chocolatey...
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

if !errorlevel! neq 0 (
    echo ERREUR lors de l'installation de Chocolatey.
    pause
    exit /b 1
)

echo [2/3] Rechargement des variables d'environnement...
REM Mise à jour du PATH pour la session actuelle
call refreshenv

REM Alternative si refreshenv n'est pas disponible
set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

REM Attendre quelques secondes pour que l'installation se termine
timeout /t 3 /nobreak >nul

echo [3/3] Installation de FFmpeg via Chocolatey...
choco install ffmpeg -y

if !errorlevel! neq 0 (
    echo ERREUR lors de l'installation de FFmpeg.
    echo Tentative avec une méthode alternative...
    "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" install ffmpeg -y
)

echo.
echo =====================================
echo Installation terminée avec succès !
echo =====================================
echo.
echo FFmpeg est maintenant disponible dans votre PATH.
echo Vous pouvez tester avec la commande : ffmpeg -version
echo.
pause
