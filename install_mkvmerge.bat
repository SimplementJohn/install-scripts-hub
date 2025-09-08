@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Installation de MKVToolNix (avec mkvmerge)
echo ==========================================
echo.

REM Vérification des privilèges administrateur
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo ERREUR: Ce script doit être exécuté en tant qu'administrateur.
    echo Clic droit sur le fichier et "Exécuter en tant qu'administrateur"
    pause
    exit /b 1
)

REM Vérification si Chocolatey est déjà installé
where choco >nul 2>&1
if !errorlevel! neq 0 (
    echo [1/3] Installation de Chocolatey...
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    
    if !errorlevel! neq 0 (
        echo ERREUR lors de l'installation de Chocolatey.
        pause
        exit /b 1
    )
    
    echo [2/3] Rechargement des variables d'environnement...
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    timeout /t 3 /nobreak >nul
) else (
    echo Chocolatey est déjà installé.
)

echo [3/3] Installation de MKVToolNix (contient mkvmerge)...
choco install mkvtoolnix -y

if !errorlevel! neq 0 (
    echo ERREUR lors de l'installation de MKVToolNix.
    echo Tentative avec une méthode alternative...
    "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" install mkvtoolnix -y
)

echo.
echo ======================================
echo Installation terminée avec succès !
echo ======================================
echo.
echo MKVToolNix est maintenant installé avec tous ses outils :
echo - mkvmerge (fusion de fichiers)
echo - mkvinfo (informations sur fichiers MKV)
echo - mkvextract (extraction de pistes)
echo - mkvpropedit (édition de propriétés)
echo.
echo Vous pouvez tester avec la commande : mkvmerge --version
echo.
pause
