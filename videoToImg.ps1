#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('mp3','wav','aac','flac')]
    [string]$OutputFormat = 'mp3'
)

Clear-Host

# =================== BANNER ===================
Write-Host "____   ____.___________  ___________________      __           _________________    ________  " -ForegroundColor Cyan
Write-Host "\   \ /   /|   \______ \ \_   _____/\_____  \   _/  |_  ____   \______   \      \  /  _____/  " -ForegroundColor Cyan
Write-Host " \   Y   / |   ||    |  \ |    __)_  /   |   \  \   __\/  _ \   |     ___/   |   \/   \  ___  " -ForegroundColor Cyan
Write-Host "  \     /  |   ||    `   \|        \/    |    \  |  | (  <_> )  |    |  /    |    \    \_\  \ " -ForegroundColor Cyan
Write-Host "   \___/   |___/_______  /_______  /\_______  /  |__|  \____/   |____|  \____|__  /\______  / " -ForegroundColor Cyan
Write-Host "                       \/        \/         \/                                  \/        \/  " -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Convertisseur video -> audio (ffmpeg) ===" -ForegroundColor Yellow
Write-Host ""

# ---------- CONFIG FFMPEG ----------
$ffmpegPath = "ffmpeg"   # ou chemin complet: C:\Tools\ffmpeg\bin\ffmpeg.exe

# Verif ffmpeg
try {
    $null = & $ffmpegPath -version 2>$null
} catch {
    Write-Host "Erreur: ffmpeg introuvable. Ajoute le au PATH ou modifie `$ffmpegPath." -ForegroundColor Red
    Write-Host ""
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}

# ---------- SELECTION FICHIER VIDEO ----------
Add-Type -AssemblyName System.Windows.Forms | Out-Null
$ofd = New-Object System.Windows.Forms.OpenFileDialog
$ofd.Title  = "Selectionne une video a convertir"
$ofd.Filter = "Videos|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.flv;*.webm|Tous les fichiers|*.*"
$ofd.Multiselect = $false

$null = $ofd.ShowDialog()
if (-not $ofd.FileName) {
    Write-Host "Aucun fichier selectionne. Fin du script." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuie sur Entree pour quitter"
    exit 0
}

$inputFile  = $ofd.FileName
$inputName  = [System.IO.Path]::GetFileName($inputFile)
$inputDir   = [System.IO.Path]::GetDirectoryName($inputFile)

# ---------- NOM DU FICHIER DE SORTIE ----------
$defaultBase = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)

Write-Host ""
Write-Host "Nom par defaut du fichier de sortie: " -NoNewline
Write-Host $defaultBase -ForegroundColor Green

$customName = Read-Host "Tape un nom de fichier de sortie (sans extension) ou laisse vide pour garder le nom par defaut"

if ([string]::IsNullOrWhiteSpace($customName)) {
    $baseName = $defaultBase
} else {
    # Nettoyage simple des caracteres invalides pour un nom de fichier Windows. [web:60]
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $cleanChars = $customName.ToCharArray() | Where-Object { $invalid -notcontains $_ }
    $baseName = -join $cleanChars
    if ([string]::IsNullOrWhiteSpace($baseName)) {
        $baseName = $defaultBase
    }
}

$outputFile = Join-Path $inputDir ("{0}.{1}" -f $baseName, $OutputFormat)

Write-Host ""
Write-Host "Fichier video : $inputName" -ForegroundColor Green
Write-Host "Dossier       : $inputDir"  -ForegroundColor DarkGray
Write-Host "Sortie audio  : $([System.IO.Path]::GetFileName($outputFile))" -ForegroundColor Green
Write-Host ""

# ---------- DUREE VIDEO (FFPROBE) ----------
Write-Host "Analyse de la duree de la video..." -ForegroundColor Cyan

$ffprobeExe = $ffmpegPath -replace "ffmpeg","ffprobe"
$ffprobeArgs = @(
    "-v", "error",
    "-show_entries", "format=duration",
    "-of", "default=noprint_wrappers=1:nokey=1",
    "-i", $inputFile
)

$totalSeconds = 0
try {
    $durationStr = & $ffprobeExe @ffprobeArgs 2>$null
    if ($durationStr -and [double]::TryParse($durationStr, [ref]([double]0))) {
        [double]$totalSeconds = [math]::Round([double]$durationStr)
    }
} catch {
    Write-Host "Impossible de lire la duree, la barre de progression sera approximative." -ForegroundColor Yellow
}

# ---------- CONVERSION AVEC PROGRESSION ----------
Write-Host "Conversion en cours..." -ForegroundColor Cyan
Write-Host ""

# Utilisation de -progress - pour recuperer out_time_ms. [web:53][web:54]
$ffmpegArgs = @(
    "-y",
    "-i", $inputFile,
    "-vn",
    "-acodec", "libmp3lame",
    "-b:a", "192k",
    "-progress", "-",
    "-nostats",
    "-loglevel", "error",
    $outputFile
)

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName               = $ffmpegPath
$psi.Arguments              = $ffmpegArgs -join " "
$psi.UseShellExecute        = $false
$psi.RedirectStandardOutput = $true   # flux -progress
$psi.RedirectStandardError  = $true
$psi.CreateNoWindow         = $true

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$null = $proc.Start()

$stdOut = $proc.StandardOutput
$stdErr = $proc.StandardError

$currentSeconds = 0
$percent        = 0
$lastUpdate     = Get-Date

# petit spinner pour montrer l activite
$spinnerChars = @("|","/","-","\")
$spinnerIndex = 0

while (-not $proc.HasExited) {

    # Lecture non bloquante de la sortie -progress
    while (-not $stdOut.EndOfStream) {
        $line = $stdOut.ReadLine()

        if ($line -match "^out_time_ms=(\d+)$") {
            $ms = [double]$matches[1]
            $currentSeconds = [math]::Round($ms / 1000000, 0)
            $lastUpdate = Get-Date
        }
    }

    # Calcul du pourcentage base sur la duree totale si dispo
    if ($totalSeconds -gt 0) {
        $percent = [math]::Min(100, [int](($currentSeconds / $totalSeconds) * 100))
    }

    # Anti-freeze visuel: si aucune nouvelle info depuis 1s, on avance doucement (< 95%)
    $sinceLast = (Get-Date) - $lastUpdate
    if ($sinceLast.TotalSeconds -ge 1 -and $percent -lt 95) {
        $percent += 1
        $lastUpdate = Get-Date
    }

    # Spinner
    $spinnerChar = $spinnerChars[$spinnerIndex % $spinnerChars.Count]
    $spinnerIndex++

    $statusText = "{0}% {1}  Temps: {2}s / {3}s" -f $percent, $spinnerChar, $currentSeconds, $totalSeconds

    Write-Progress `
        -Activity "Conversion video -> audio" `
        -Status   $statusText `
        -PercentComplete $percent

    Start-Sleep -Milliseconds 250
}

$proc.WaitForExit()
Write-Progress -Activity "Conversion video -> audio" -Completed

Write-Host ""

if ($proc.ExitCode -eq 0 -and (Test-Path $outputFile)) {
    Write-Host "Conversion terminee avec succes." -ForegroundColor Green
    Write-Host "Fichier audio cree : $outputFile" -ForegroundColor Green
} else {
    Write-Host "La conversion a echoue (code: $($proc.ExitCode))." -ForegroundColor Red
    $errText = $stdErr.ReadToEnd()
    if ($errText) {
        Write-Host ""
        Write-Host "Details ffmpeg :" -ForegroundColor Yellow
        Write-Host $errText
    }
}

Write-Host ""
Read-Host "Appuie sur Entree pour fermer la fenetre"
