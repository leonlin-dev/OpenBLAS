<#
.SYNOPSIS
    Install OpenBLAS binary package into ZW_3rdLibs_VC14 layout.
#>
param(
    [Parameter(Mandatory = $true)][string]$ZwRoot
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$m    = Get-Content (Join-Path $PSScriptRoot 'zw.json') -Raw | ConvertFrom-Json
$dest = Join-Path $ZwRoot $m.install.zw_dir

$cacheDir = Join-Path $repo 'dist'
if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Force $cacheDir | Out-Null }
$zipPath = Join-Path $cacheDir $m.asset.filename

# Use local _3rdlib_build cache if present and uncopied
$legacyZip = Join-Path $repo '..\..\_3rdlib_build\openblas.zip'
if ((-not (Test-Path $zipPath)) -and (Test-Path $legacyZip)) {
    Copy-Item $legacyZip $zipPath
}

if (-not (Test-Path $zipPath)) {
    Write-Host "Downloading $($m.asset.url)..."
    Invoke-WebRequest -Uri $m.asset.url -OutFile $zipPath
}

# Verify SHA256
$hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
if ($hash -ne $m.asset.sha256.ToLower()) {
    throw "SHA256 mismatch for $($m.asset.filename): expected $($m.asset.sha256), got $hash"
}

# Unpack
$extractDir = Join-Path $cacheDir 'unpacked'
if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
New-Item -ItemType Directory -Force $extractDir | Out-Null
& tar -xf $zipPath -C $extractDir

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force $dest | Out-Null

Copy-Item "$extractDir\*" $dest -Recurse -Force
Write-Host "installed $($m.name) $($m.version) -> $dest"
