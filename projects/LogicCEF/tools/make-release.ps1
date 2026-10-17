# Bouwt logicCEF.exe opnieuw en maakt de Windows-release-zip en het
# installatieprogramma (Inno Setup 6, logic.iss).
#
#   powershell -ExecutionPolicy Bypass -File projects\LogicCEF\tools\make-release.ps1 [-Version 1.4.0] [-NoBuild]
#
# Resultaat in C:\fpcupdeluxe\publish\release:
#   Logic-<versie>-win64.zip    uitpakken en logicCEF.exe starten
#   Logic-<versie>-setup.exe    installeert per gebruiker, zonder beheerdersrechten
#
# Zip en installatieprogramma krijgen precies dezelfde inhoud:
#   - programma, taal.ini en CEF-runtime uit Resultaat
#   - panels, ini en html uit Git (de laatste commit, HEAD). Niet-gecommitte
#     wijzigingen en testpanelen in Resultaat gaan dus NIET mee; het script
#     waarschuwt als er zulke wijzigingen zijn.
#   - help vers opgebouwd uit helpsrc in een lege map (geen oude bestanden)
# Cache, logs, backups en ontwikkelbestanden blijven eruit.

param(
  [string]$Version = '1.4.0',
  [string]$Lazbuild = 'C:\fpcupdeluxe\lazarus\lazbuild.exe',
  [string]$OutDir = 'C:\fpcupdeluxe\publish\release',
  [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$proj = Split-Path $PSScriptRoot -Parent   # projects\LogicCEF (dit script staat in tools)
$repo = (Resolve-Path (Join-Path $proj '..\..')).Path
$src  = Join-Path $proj 'Resultaat'

if (-not $NoBuild) {
  & $Lazbuild --build-mode=Default (Join-Path $proj 'logic.lpi')
  if ($LASTEXITCODE -ne 0) { throw "lazbuild faalde ($LASTEXITCODE)" }
}

$name  = "Logic-$Version-win64"
$stage = Join-Path $env:TEMP $name
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory $stage | Out-Null

try {
  # ----------------------------------------------------------------
  # Programma en CEF-runtime (uit Resultaat)
  # ----------------------------------------------------------------
  $files = @(
    'logicCEF.exe',
    'ceflib\libcef.dll', 'ceflib\chrome_elf.dll', 'ceflib\d3dcompiler_47.dll',
    'ceflib\libEGL.dll', 'ceflib\libGLESv2.dll',
    'ceflib\vk_swiftshader.dll', 'ceflib\vk_swiftshader_icd.json', 'ceflib\vulkan-1.dll',
    'ceflib\icudtl.dat', 'ceflib\resources.pak',
    'ceflib\chrome_100_percent.pak', 'ceflib\chrome_200_percent.pak',
    'ceflib\snapshot_blob.bin', 'ceflib\v8_context_snapshot.bin'
  )
  foreach ($f in $files) {
    $p = Join-Path $src $f
    if (-not (Test-Path $p)) { throw "Ontbreekt: $p" }
    $dest = $stage
    if (Split-Path $f -Parent) { $dest = Join-Path $stage (Split-Path $f -Parent) }
    New-Item -ItemType Directory $dest -Force | Out-Null
    Copy-Item $p $dest
  }
  Copy-Item (Join-Path $src 'ceflib\locales') (Join-Path $stage 'ceflib\locales') -Recurse

  # Vaste taal.ini: nieuwe gebruikers starten in het Nederlands, los van de
  # taal die je zelf laatst koos (bestaande installaties houden hun keuze).
  Set-Content (Join-Path $stage 'taal.ini') "[Settings]`r`nLanguage=0" -Encoding ascii

  # ----------------------------------------------------------------
  # panels, ini en html uit Git (HEAD)
  # ----------------------------------------------------------------
  $gitPaths = 'panels', 'ini', 'html' | ForEach-Object { "projects/LogicCEF/Resultaat/$_" }
  $dirty = & git -C $repo status --porcelain -- $gitPaths
  if ($LASTEXITCODE -ne 0) { throw "git status faalde: is $repo een Git-repository?" }
  if ($dirty) {
    Write-Warning "Niet-gecommitte wijzigingen in panels/ini/html gaan NIET mee in de release:"
    $dirty | ForEach-Object { Write-Warning "  $_" }
  }
  $tar = Join-Path $env:TEMP "$name-data.tar"
  & git -C $repo archive --format=tar -o $tar HEAD -- $gitPaths
  if ($LASTEXITCODE -ne 0) { throw "git archive faalde ($LASTEXITCODE)" }
  $gitDir = Join-Path $env:TEMP "$name-git"
  if (Test-Path $gitDir) { Remove-Item $gitDir -Recurse -Force }
  New-Item -ItemType Directory $gitDir | Out-Null
  & "$env:SystemRoot\System32\tar.exe" -xf $tar -C $gitDir
  if ($LASTEXITCODE -ne 0) { throw "tar faalde ($LASTEXITCODE)" }
  foreach ($d in 'panels', 'ini', 'html') {
    Copy-Item (Join-Path $gitDir "projects\LogicCEF\Resultaat\$d") (Join-Path $stage $d) -Recurse
  }
  Remove-Item $tar, $gitDir -Recurse -Force

  # ----------------------------------------------------------------
  # Help vers opbouwen uit helpsrc, in een lege map
  # ----------------------------------------------------------------
  & powershell -ExecutionPolicy Bypass -File (Join-Path $proj 'helpsrc\make-help.ps1') -Out (Join-Path $stage 'help')
  if ($LASTEXITCODE -ne 0) { throw "make-help.ps1 faalde ($LASTEXITCODE)" }

  # De hele help als PDF per taal (help\Logic-help-<taal>.pdf), ook los
  # naast de zip als Logic-<versie>-help-<taal>.pdf
  & powershell -ExecutionPolicy Bypass -File (Join-Path $proj 'helpsrc\make-help-pdf.ps1') -Out (Join-Path $stage 'help') -Version $Version
  if ($LASTEXITCODE -ne 0) { throw "make-help-pdf.ps1 faalde ($LASTEXITCODE)" }
  New-Item -ItemType Directory $OutDir -Force | Out-Null
  foreach ($pdf in Get-ChildItem (Join-Path $stage 'help') -Filter 'Logic-help-*.pdf') {
    Copy-Item $pdf.FullName (Join-Path $OutDir ($pdf.Name -replace '^Logic-help-', "Logic-$Version-help-"))
  }

  Remove-Item (Join-Path $stage 'ini\comboColor.ini') -ErrorAction SilentlyContinue
  Get-ChildItem $stage -Recurse -Include *.bak, *.log | Remove-Item -Force

  Copy-Item (Join-Path $repo 'LICENSE') $stage
  Copy-Item (Join-Path $repo 'README.md') $stage

  # ----------------------------------------------------------------
  # Zip. Zelf inpakken i.p.v. Compress-Archive: dat zet in Windows
  # PowerShell 5.1 backslashes in de paden, waar uitpakkers buiten
  # Windows (unzip onder Linux) over struikelen.
  # ----------------------------------------------------------------
  New-Item -ItemType Directory $OutDir -Force | Out-Null
  $zip = Join-Path $OutDir "$name.zip"
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::Open($zip, 'Create')
  try {
    foreach ($item in Get-ChildItem $stage -Recurse -File) {
      $entry = $item.FullName.Substring($stage.Length + 1).Replace('\', '/')
      [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $item.FullName, $entry, 'Optimal') | Out-Null
    }
  } finally {
    $archive.Dispose()
  }
  $mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
  Write-Host "Klaar: $zip ($mb MB)"

  # ----------------------------------------------------------------
  # Installatieprogramma met Inno Setup 6, uit dezelfde samengestelde map
  # ----------------------------------------------------------------
  $iscc = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
  if (Test-Path $iscc) {
    & $iscc /Q "/DMyAppVersion=$Version" "/DSrc=$stage" "/O$OutDir" (Join-Path $proj 'logic.iss')
    if ($LASTEXITCODE -ne 0) { throw "ISCC faalde ($LASTEXITCODE)" }
    $setup = Join-Path $OutDir "Logic-$Version-setup.exe"
    $mb = [math]::Round((Get-Item $setup).Length / 1MB, 1)
    Write-Host "Klaar: $setup ($mb MB)"
  } else {
    Write-Host "Inno Setup 6 niet gevonden: geen installatieprogramma gemaakt."
  }
}
finally {
  if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
}
