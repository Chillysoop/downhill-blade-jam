# Downhill Blade Jam launcher.
# Checks the "latest-build" GitHub release, downloads it if it is newer than
# the installed copy, then starts the game. If there is no internet it just
# starts whatever is installed. The launcher also refreshes itself from the
# same release so fixes to it arrive automatically.
#
# Works on Windows PowerShell 5.1 (built into Windows 10/11).
# Set DBJ_NO_LAUNCH=1 to update without starting the game (used by CI).

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # progress bars make downloads crawl on PS 5.1

$Repo      = 'Chillysoop/downhill-blade-jam'
$Tag       = 'latest-build'
$AssetName = 'DownhillBladeJam-windows.zip'
$Root      = Join-Path $env:LOCALAPPDATA 'DownhillBladeJam'
$GameDir   = Join-Path $Root 'game'
$Exe       = Join-Path $GameDir 'DownhillBladeJam.exe'
$VerFile   = Join-Path $Root 'installed-version.txt'
$Headers   = @{ 'User-Agent' = 'DownhillBladeJam-Launcher'; 'Accept' = 'application/vnd.github+json' }

$Host.UI.RawUI.WindowTitle = 'Downhill Blade Jam'
New-Item -ItemType Directory -Force -Path $GameDir | Out-Null
# Keep a log of the last launch so problems can be diagnosed.
try { Start-Transcript -LiteralPath (Join-Path $Root 'launcher.log') -Force | Out-Null } catch {}
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Read-Installed {
    if (Test-Path $VerFile) { return (Get-Content -LiteralPath $VerFile -Raw).Trim() }
    return ''
}

try {
    Write-Host 'Checking for updates...'
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/tags/$Tag" -Headers $Headers -TimeoutSec 20
    $asset = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
    if ($null -eq $asset) { throw 'No game build found in the release yet.' }

    $latest = "$($asset.id)-$($asset.updated_at)"
    if ($latest -ne (Read-Installed) -or -not (Test-Path $Exe)) {
        $mb = [math]::Round($asset.size / 1MB)
        Write-Host "Downloading the newest build ($mb MB)..."
        $zip = Join-Path $env:TEMP "DownhillBladeJam-$($asset.id).zip"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -Headers @{ 'User-Agent' = $Headers['User-Agent'] } -UseBasicParsing -TimeoutSec 600

        # Close a running copy so its files can be replaced.
        Get-Process -Name 'DownhillBladeJam' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
        $staging = Join-Path $Root 'staging'
        if (Test-Path $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
        Expand-Archive -LiteralPath $zip -DestinationPath $staging -Force
        if (-not (Test-Path (Join-Path $staging 'DownhillBladeJam.exe'))) { throw 'Downloaded build is missing the game.' }
        if (Test-Path $GameDir) { Remove-Item -LiteralPath $GameDir -Recurse -Force }
        Move-Item -LiteralPath $staging -Destination $GameDir
        Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
        Set-Content -LiteralPath $VerFile -Value $latest
        $info = Join-Path $GameDir 'build-info.txt'
        if (Test-Path $info) { Write-Host "Updated to build $((Get-Content -LiteralPath $info -Raw).Trim())" }
    } else {
        Write-Host 'Already up to date.'
    }

    # Refresh the launcher itself for next time.
    $self = $release.assets | Where-Object { $_.name -eq 'launcher.ps1' } | Select-Object -First 1
    if ($null -ne $self) {
        $tmp = Join-Path $Root 'launcher.new.ps1'
        Invoke-WebRequest -Uri $self.browser_download_url -OutFile $tmp -Headers @{ 'User-Agent' = $Headers['User-Agent'] } -UseBasicParsing -TimeoutSec 60
        if ((Get-Item -LiteralPath $tmp).Length -gt 500) {
            Move-Item -LiteralPath $tmp -Destination (Join-Path $Root 'launcher.ps1') -Force
        } else {
            Remove-Item -LiteralPath $tmp -Force
        }
    }
} catch {
    Write-Host "Couldn't update: $($_.Exception.Message)"
    if (Test-Path $Exe) { Write-Host 'Starting the installed version instead.' ; Start-Sleep -Seconds 3 }
    else { Read-Host 'Press Enter to close' }
}

try { Stop-Transcript | Out-Null } catch {}
if ($env:DBJ_NO_LAUNCH -eq '1') { exit 0 }

if (Test-Path $Exe) {
    Start-Process -FilePath $Exe -WorkingDirectory $GameDir
} else {
    Write-Host 'No build is installed yet and the download failed. Check your internet connection and try again.'
    Read-Host 'Press Enter to close'
}
