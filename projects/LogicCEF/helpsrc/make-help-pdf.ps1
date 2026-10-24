<#
  Maakt van de help van Logic per taal een PDF: Logic-help-<taal>.pdf.

  Alle bronpagina's van helpsrc\<taal> worden in de volgorde van de navigatie
  (de lessen na het leerpad) samengevoegd tot een document met titelblad en
  inhoudsopgave. Links tussen pagina's worden sprongen binnen de PDF, de
  knoppen "Open dit voorbeeld" vallen weg en de oplossingen staan open.
  Microsoft Edge drukt het document daarna af als PDF (zonder venster).

  Gebruik (na make-help.ps1, want de afbeeldingen komen uit de help-map):
      powershell -ExecutionPolicy Bypass -File helpsrc\make-help-pdf.ps1 [-Out <help-map>] [-Langs nl,en]
#>
param(
  [string]$Out,
  [string[]]$Langs = @('nl', 'en', 'fr', 'de'),
  [string]$Version
)

$ErrorActionPreference = 'Stop'
$Src = $PSScriptRoot
$Proj = Split-Path $Src -Parent
if (-not $Out) { $Out = Join-Path $Proj 'Resultaat/help' }
if (-not (Test-Path (Join-Path $Out 'help.css'))) { throw "Eerst make-help.ps1 uitvoeren: $Out bevat geen help." }
if (-not $Version) {
  $m = Select-String -Path (Join-Path $Proj 'uabout.pas') -Pattern "AppVersion\s*=\s*'([^']+)'" | Select-Object -First 1
  if ($m) { $Version = $m.Matches[0].Groups[1].Value }
}

$Edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
          "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Edge) { throw 'Microsoft Edge niet gevonden: nodig om de PDF te maken.' }

# zelfde volgorde als de navigatie in make-help.ps1; de lessen na 'leerpad'
$Order = @('index', 'installeren', 'werkwijze', 'leerpad', 'LESSEN', 'knoppen', 'paneel', 'onderdelenbalk',
           'invoer', 'verwerking', 'uitvoer', 'voeding', 'verbindingen', 'objecten', 'simulatie', 'logicrun', 'instellingen')

# teksten op het titelblad (HTML-entiteiten: dit script blijft ASCII)
$Txt = @{
  nl = @{ sub = 'Simulator voor digitale schakelingen'; help = 'Help'; toc = 'Inhoud'; ver = 'Versie' }
  en = @{ sub = 'Simulator for digital circuits'; help = 'Help'; toc = 'Contents'; ver = 'Version' }
  fr = @{ sub = 'Simulateur de circuits num&eacute;riques'; help = 'Aide'; toc = 'Sommaire'; ver = 'Version' }
  de = @{ sub = 'Simulator f&uuml;r digitale Schaltungen'; help = 'Hilfe'; toc = 'Inhalt'; ver = 'Version' }
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)

$PrintCss = @'
body { background: #fff; }
.doc { max-width: none; padding: 0; }
.page { break-before: page; }
.cover { text-align: center; padding-top: 180px; }
.cover img { width: 96px; height: 96px; }
.cover h1 { font-size: 40px; margin: 18px 0 6px; }
.cover p { color: var(--muted); font-size: 18px; margin: 4px 0; }
ol.toc { columns: 2; font-size: 14px; }
ol.toc li { margin-bottom: 4px; break-inside: avoid; }
ol.toc a { color: var(--text); text-decoration: none; }
table, figure, .tip, .goal, details, pre { break-inside: avoid; }
h1, h2, h3 { break-after: avoid; }
a { text-decoration: none; }
details summary { color: var(--text); }
.cards { display: block; }
.card { display: block; margin-bottom: 6px; }
@page { size: A4; margin: 15mm 14mm; }
'@

foreach ($L in $Langs) {
  $LangDir = Join-Path $Src $L
  if (-not (Test-Path $LangDir)) { continue }
  $Lessons = @(Get-ChildItem $LangDir -Filter 'les*.html' | Sort-Object Name | ForEach-Object { $_.BaseName })
  $Pages = foreach ($P in $Order) { if ($P -eq 'LESSEN') { $Lessons } else { $P } }

  $Toc = New-Object System.Text.StringBuilder
  $Body = New-Object System.Text.StringBuilder
  foreach ($P in $Pages) {
    $File = Join-Path $LangDir "$P.html"
    if (-not (Test-Path $File)) { continue }
    $H = [IO.File]::ReadAllText($File, $Utf8)
    $Title = $P
    if ($H -match '^\s*<!--\s*titel:\s*(.*?)\s*-->') {
      $Title = $Matches[1]
      $H = $H.Substring($Matches[0].Length)
    }
    # niet in een PDF: de knop "Open dit voorbeeld" en vorige/volgende
    $H = $H -replace '(?s)\s*<p><a class="open"[^>]*>.*?</a></p>', ''
    $H = $H -replace '(?s)\s*<div class="pager">.*?</div>', ''
    # oplossingen open
    $H = $H -replace '<details>', '<details open>'
    # ankers uniek maken per pagina, links omzetten naar sprongen in het document
    $H = $H -replace 'id="([^"]+)"', ('id="' + $P + '-$1"')
    $H = $H -replace 'href="#([^"]+)"', ('href="#' + $P + '-$1"')
    $H = $H -replace 'href="([a-z0-9]+)\.html#([^"]+)"', 'href="#$1-$2"'
    $H = $H -replace 'href="([a-z0-9]+)\.html"', 'href="#$1"'
    $Esc = $Title.Replace('&', '&amp;')
    [void]$Toc.AppendLine("    <li><a href=""#$P"">$Esc</a></li>")
    [void]$Body.AppendLine("<section class=""page"" id=""$P"">")
    [void]$Body.AppendLine($H.Trim())
    [void]$Body.AppendLine('</section>')
  }

  $T = $Txt[$L]
  $Html = @"
<!DOCTYPE html>
<html lang="$L">
<head>
<meta charset="utf-8">
<title>Logic - $($T.help)</title>
<link rel="stylesheet" href="../help.css">
<style>
$PrintCss
</style>
</head>
<body>
<main class="doc">
<section class="cover">
  <img src="../img/logo.png" alt="">
  <h1>Logic</h1>
  <p>$($T.sub)</p>
  <p><b>$($T.help)</b> &middot; $($T.ver) $Version</p>
</section>
<section class="page" id="inhoud">
  <h1>$($T.toc)</h1>
  <ol class="toc">
$($Toc.ToString().TrimEnd())
  </ol>
</section>
$($Body.ToString())
</main>
</body>
</html>
"@
  $Tmp = Join-Path $Out "$L/_pdf.html"
  [IO.File]::WriteAllText($Tmp, $Html, $Utf8)
  $Pdf = Join-Path $Out "Logic-help-$L.pdf"
  if (Test-Path $Pdf) { Remove-Item $Pdf -Force }
  $Uri = ([Uri](Resolve-Path $Tmp).Path).AbsoluteUri
  $UserDir = Join-Path $env:TEMP 'logic-help-pdf-edge'
  $Args = @('--headless=new', '--disable-gpu', '--no-first-run', '--no-pdf-header-footer',
            "--user-data-dir=`"$UserDir`"", "--print-to-pdf=`"$Pdf`"", $Uri)
  Start-Process -FilePath $Edge -ArgumentList $Args -Wait -WindowStyle Hidden
  Remove-Item $Tmp -Force
  if (-not (Test-Path $Pdf)) { throw "PDF niet gemaakt: $Pdf" }
  $kb = [math]::Round((Get-Item $Pdf).Length / 1KB)
  Write-Host "PDF klaar: $Pdf ($kb KB)"
}
