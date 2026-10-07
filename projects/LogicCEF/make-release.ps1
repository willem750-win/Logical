# Bouwt logicCEF.exe opnieuw en maakt de Windows-release-zip en het
# installatieprogramma (Inno Setup 6, logic.iss).
#
#   powershell -ExecutionPolicy Bypass -File projects\LogicCEF\make-release.ps1 [-Version 1.0.1] [-NoBuild]
#
# Resultaat in C:\fpcupdeluxe\publish\release:
#   Logic-<versie>-win64.zip    uitpakken en logicCEF.exe starten
#   Logic-<versie>-setup.exe    installeert per gebruiker, zonder beheerdersrechten
# De zip bevat het programma, de CEF-runtime, help, html, panels, ini en taal.ini.
# Cache, logs, backups en ontwikkelbestanden blijven eruit.

param(
  [string]$Version = '1.0.1',
  [string]$Lazbuild = 'C:\fpcupdeluxe\lazarus\lazbuild.exe',
  [string]$OutDir = 'C:\fpcupdeluxe\publish\release',
  [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$proj = $PSScriptRoot
$src  = Join-Path $proj 'Resultaat'

if (-not $NoBuild) {
  & $Lazbuild --build-mode=Default (Join-Path $proj 'logic.lpi')
  if ($LASTEXITCODE -ne 0) { throw "lazbuild faalde ($LASTEXITCODE)" }
}

# Help opnieuw opbouwen uit helpsrc
& powershell -ExecutionPolicy Bypass -File (Join-Path $proj 'helpsrc\make-help.ps1')
if ($LASTEXITCODE -ne 0) { throw "make-help.ps1 faalde ($LASTEXITCODE)" }

$name  = "Logic-$Version-win64"
$stage = Join-Path $env:TEMP $name
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory $stage | Out-Null

# Programma en CEF-runtime
$files = @(
  'logicCEF.exe', 'taal.ini',
  'libcef.dll', 'chrome_elf.dll', 'd3dcompiler_47.dll', 'libEGL.dll', 'libGLESv2.dll',
  'vk_swiftshader.dll', 'vk_swiftshader_icd.json', 'vulkan-1.dll',
  'icudtl.dat', 'resources.pak', 'chrome_100_percent.pak', 'chrome_200_percent.pak',
  'snapshot_blob.bin', 'v8_context_snapshot.bin'
)
foreach ($f in $files) {
  $p = Join-Path $src $f
  if (-not (Test-Path $p)) { throw "Ontbreekt: $p" }
  Copy-Item $p $stage
}

# Datamappen
foreach ($d in 'locales', 'help', 'html', 'panels', 'ini') {
  Copy-Item (Join-Path $src $d) (Join-Path $stage $d) -Recurse
}
Remove-Item (Join-Path $stage 'ini\comboColor.ini') -ErrorAction SilentlyContinue
Get-ChildItem $stage -Recurse -Include *.bak, *.log | Remove-Item -Force

Copy-Item (Join-Path $proj '..\..\LICENSE') $stage
Copy-Item (Join-Path $proj '..\..\README.md') $stage

New-Item -ItemType Directory $OutDir -Force | Out-Null
$zip = Join-Path $OutDir "$name.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $stage -Recurse -Force

$mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "Klaar: $zip ($mb MB)"

# Installatieprogramma met Inno Setup 6 (logic.iss), als het aanwezig is
$iscc = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
if (Test-Path $iscc) {
  & $iscc /Q "/DMyAppVersion=$Version" "/O$OutDir" (Join-Path $proj 'logic.iss')
  if ($LASTEXITCODE -ne 0) { throw "ISCC faalde ($LASTEXITCODE)" }
  $setup = Join-Path $OutDir "Logic-$Version-setup.exe"
  $mb = [math]::Round((Get-Item $setup).Length / 1MB, 1)
  Write-Host "Klaar: $setup ($mb MB)"
} else {
  Write-Host "Inno Setup 6 niet gevonden: geen installatieprogramma gemaakt."
}
