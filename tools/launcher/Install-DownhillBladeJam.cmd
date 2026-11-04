<# : Downhill Blade Jam installer (runs as a batch file, then as PowerShell)
@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression ([System.IO.File]::ReadAllText('%~f0'))"
exit /b %errorlevel%
#>
# Double-click this file once. It installs the auto-updating launcher, puts a
# "Downhill Blade Jam" shortcut on your Desktop and downloads the newest build.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$Root     = Join-Path $env:LOCALAPPDATA 'DownhillBladeJam'
$Launcher = Join-Path $Root 'launcher.ps1'
$Exe      = Join-Path $Root 'game\DownhillBladeJam.exe'
New-Item -ItemType Directory -Force -Path $Root | Out-Null

Write-Host 'Installing the Downhill Blade Jam launcher...'
Invoke-WebRequest -Uri 'https://github.com/Chillysoop/downhill-blade-jam/releases/download/latest-build/launcher.ps1' `
    -OutFile $Launcher -Headers @{ 'User-Agent' = 'DownhillBladeJam-Installer' } -UseBasicParsing -TimeoutSec 60

# First run downloads the game without starting it.
$env:DBJ_NO_LAUNCH = '1'
& powershell -NoProfile -ExecutionPolicy Bypass -File $Launcher
Remove-Item Env:\DBJ_NO_LAUNCH

$desktop = [Environment]::GetFolderPath('Desktop')
$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut((Join-Path $desktop 'Downhill Blade Jam.lnk'))
# The game updates itself on start, so the shortcut opens it directly.
$lnk.TargetPath = $Exe
$lnk.Arguments = ''
$lnk.WorkingDirectory = Split-Path $Exe
$lnk.Description = 'Downhill Blade Jam (updates itself when launched)'
$lnk.IconLocation = "$Exe,0"
$lnk.Save()

Write-Host ''
Write-Host 'Done! Use the "Downhill Blade Jam" shortcut on your Desktop.'
Write-Host 'The game checks for a newer build every time you open it.'
if ($env:CI -ne 'true') { Read-Host 'Press Enter to close' }
