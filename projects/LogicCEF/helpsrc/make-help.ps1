<#
  Bouwt de help van Logic op uit de bronbestanden in deze map.

      helpsrc\help.css            -> Resultaat\help\help.css
      helpsrc\img\*.png           -> Resultaat\help\img\
      helpsrc\<taal>\<pagina>.html  (enkel de inhoud van <main>)
                                  -> Resultaat\help\<taal>\<pagina>.html

  Elke bronpagina begint met een regel  <!-- titel: ... -->  die als
  paginatitel gebruikt wordt. De navigatie links en de taalknoppen worden
  hier toegevoegd, zodat ze op alle pagina's gelijk blijven.

  Gebruik:
      powershell -ExecutionPolicy Bypass -File helpsrc\make-help.ps1
#>
param([string]$Out)

$ErrorActionPreference = 'Stop'
$Src = $PSScriptRoot
if (-not $Out) { $Out = Join-Path (Split-Path $Src -Parent) 'Resultaat\help' }

$Langs = 'nl', 'en', 'fr', 'de'
$LangLabel = @{ nl = 'NL'; en = 'EN'; fr = 'FR'; de = 'DE' }

# Volgorde en groepen van de navigatie. 'group:' = tussenkop.
$Pages = @(
  'index', 'werkwijze',
  'group:scherm', 'knoppen', 'paneel', 'onderdelenbalk',
  'group:onderdelen', 'invoer', 'verwerking', 'uitvoer',
  'group:werken', 'verbindingen', 'objecten', 'simulatie', 'instellingen'
)

$Nav = @{
  nl = @{ index = 'Start'; werkwijze = 'Aan de slag'; knoppen = 'Knoppenbalk'; paneel = 'Paneel &amp; raster';
          onderdelenbalk = 'Onderdelenbalk'; invoer = 'Invoer'; verwerking = 'Verwerking'; uitvoer = 'Uitvoer';
          verbindingen = 'Verbindingen'; objecten = 'Objecten bedienen'; simulatie = 'Simulatie';
          instellingen = 'Instellingen &amp; taal';
          'group:scherm' = 'Het scherm'; 'group:onderdelen' = 'Onderdelen'; 'group:werken' = 'Werken met Logic' }
  en = @{ index = 'Start'; werkwijze = 'Getting started'; knoppen = 'Button bar'; paneel = 'Panel &amp; grid';
          onderdelenbalk = 'Component bar'; invoer = 'Inputs'; verwerking = 'Processing'; uitvoer = 'Outputs';
          verbindingen = 'Connections'; objecten = 'Working with objects'; simulatie = 'Simulation';
          instellingen = 'Settings &amp; language';
          'group:scherm' = 'The window'; 'group:onderdelen' = 'Components'; 'group:werken' = 'Working with Logic' }
  fr = @{ index = 'Accueil'; werkwijze = 'Premiers pas'; knoppen = 'Barre de boutons'; paneel = 'Panneau &amp; grille';
          onderdelenbalk = 'Barre des composants'; invoer = 'Entrées'; verwerking = 'Traitement'; uitvoer = 'Sorties';
          verbindingen = 'Connexions'; objecten = 'Manipuler les objets'; simulatie = 'Simulation';
          instellingen = 'Réglages &amp; langue';
          'group:scherm' = 'La fenêtre'; 'group:onderdelen' = 'Composants'; 'group:werken' = 'Travailler avec Logic' }
  de = @{ index = 'Start'; werkwijze = 'Erste Schritte'; knoppen = 'Schaltflächenleiste'; paneel = 'Panel &amp; Raster';
          onderdelenbalk = 'Bauteilleiste'; invoer = 'Eingänge'; verwerking = 'Verarbeitung'; uitvoer = 'Ausgänge';
          verbindingen = 'Verbindungen'; objecten = 'Objekte bedienen'; simulatie = 'Simulation';
          instellingen = 'Einstellungen &amp; Sprache';
          'group:scherm' = 'Das Fenster'; 'group:onderdelen' = 'Bauteile'; 'group:werken' = 'Arbeiten mit Logic' }
}

# Pictogram per navigatie-item
$NavIcon = @{
  knoppen = 'knop-simuleren'; paneel = 'knop-raster'; onderdelenbalk = 'pal-verbinding';
  invoer = 'pal-schakelaar'; verwerking = 'pal-en'; uitvoer = 'pal-lamp';
  verbindingen = 'pal-verbinding'; objecten = 'knop-verwijder'; simulatie = 'knop-simuleren';
  instellingen = 'knop-instellingen'
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)

New-Item -ItemType Directory -Force $Out | Out-Null
Copy-Item (Join-Path $Src 'help.css') (Join-Path $Out 'help.css') -Force
New-Item -ItemType Directory -Force (Join-Path $Out 'img') | Out-Null
Copy-Item (Join-Path $Src 'img\*') (Join-Path $Out 'img') -Force

$Count = 0
foreach ($L in $Langs) {
  $LangDir = Join-Path $Src $L
  if (-not (Test-Path $LangDir)) { continue }
  New-Item -ItemType Directory -Force (Join-Path $Out $L) | Out-Null

  foreach ($P in $Pages | Where-Object { $_ -notlike 'group:*' }) {
    $File = Join-Path $LangDir "$P.html"
    if (-not (Test-Path $File)) { continue }
    $Body = [IO.File]::ReadAllText($File, $Utf8)
    $Title = $Nav[$L][$P]
    if ($Body -match '^\s*<!--\s*titel:\s*(.*?)\s*-->') {
      $Title = $Matches[1]
      $Body = $Body.Substring($Matches[0].Length).TrimStart()
    }

    $sb = New-Object System.Text.StringBuilder
    foreach ($N in $Pages) {
      if ($N -like 'group:*') {
        [void]$sb.AppendLine("  <div class=""group"">$($Nav[$L][$N])</div>")
        continue
      }
      $cls = if ($N -eq $P) { ' class="active"' } else { '' }
      $ico = if ($NavIcon.ContainsKey($N)) { "<img src=""../img/$($NavIcon[$N]).png"" class=""ico"" alt="""">" } else { '' }
      [void]$sb.AppendLine("  <a href=""$N.html""$cls>$ico$($Nav[$L][$N])</a>")
    }
    $LangLinks = ($Langs | ForEach-Object {
      $c = if ($_ -eq $L) { ' class="cur"' } else { '' }
      "<a href=""../$_/$P.html""$c>$($LangLabel[$_])</a>"
    }) -join ''

    $Html = @"
<!DOCTYPE html>
<html lang="$L">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$Title - Logic</title>
<link rel="stylesheet" href="../help.css">
</head>
<body>
<div class="layout">
<nav>
  <div class="brand"><img src="../img/logo.png" class="logo" alt="">Logic</div>
  <div class="langs">$LangLinks</div>
$($sb.ToString().TrimEnd())
</nav>
<main>
$($Body.TrimEnd())
</main>
</div>
</body>
</html>
"@
    [IO.File]::WriteAllText((Join-Path $Out "$L\$P.html"), $Html.Replace("`r`n", "`n"), $Utf8)
    $Count++
  }
}

# Startpagina zonder taal: doorsturen naar het Nederlands
$Redirect = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta http-equiv="refresh" content="0; url=nl/index.html">
<title>Logic - Help</title></head>
<body><a href="nl/index.html">Help</a></body></html>
"@
[IO.File]::WriteAllText((Join-Path $Out 'index.html'), $Redirect.Replace("`r`n", "`n"), $Utf8)

Write-Host "Help klaar: $Count pagina's in $Out"
