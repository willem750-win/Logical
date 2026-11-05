<#
  Verzamelt de Engelse teksten van Logic in Resultaat\lang\logic.pot, het
  sjabloon voor extra talen (zie uLangPo.pas). Een vertaler maakt daarmee in
  Poedit een <code>.po (bv. it.po) en zet die in Resultaat\lang.

  Gezocht wordt naar:
  - de Engelse tekst in Tr / MyTr / TrHelp (BTaal, NL, EN, FR, DE) en T (NL, EN, FR, DE);
  - teksten na een label lgEnglish: / stEnglish: in een case;
  - het Engelse deel van ketens als  if BTaal = 'NL' then ... else ...;
  - 'case Taal.ItemIndex of' / 'case TaalIndex of' met label 1 (Engels);
  - de sectie [lgEnglish] van StringHolderTranslations in fsettings.lfm
    (namen in de instellingen).
  Wat zo niet gevonden wordt, vindt Logic zelf: start het met --po-collect,
  dan schrijft het bij het afsluiten lang\missing-<code>.pot.

  Met -Merge worden nieuwe teksten ook achteraan in elke bestaande
  lang\*.po gezet (met lege vertaling); bestaande vertalingen blijven.

  Gebruik:
      powershell -ExecutionPolicy Bypass -File projects\LogicCEF\tools\make-pot.ps1 [-Merge]
#>
param([switch] $Merge)

$ErrorActionPreference = 'Stop'
$Tools   = $PSScriptRoot
$Project = Split-Path $Tools -Parent                    # ...\Logic\projects\LogicCEF
$Logic   = Split-Path (Split-Path $Project -Parent) -Parent
$Grid    = Join-Path (Split-Path $Logic -Parent) 'PropertyGridAdvante'
$LangDir = Join-Path $Project 'Resultaat\lang'
$Utf8    = New-Object System.Text.UTF8Encoding($false)

$Files = @()
$Files += Get-ChildItem $Logic -Filter *.pas | Where-Object { $_.Name -notmatch '_new|backup|kopie' }
$Files += Get-ChildItem $Project -Filter *.pas
$G = Join-Path $Grid 'AdvancedPropertyGridComponent.pas'
if (Test-Path $G) { $Files += Get-Item $G }

# msgid -> lijst van verwijzingen (bestand:regel)
$Found = New-Object System.Collections.Specialized.OrderedDictionary([StringComparer]::Ordinal)
function Add-Msg([string]$Text, [string]$Ref) {
  if ($Text -notmatch '[A-Za-z]') { return }
  if ($Text -match '^(NL|ENG|FR|DU|EN|DE)$') { return }
  if (-not $Found.Contains($Text)) { $Found[$Text] = New-Object System.Collections.ArrayList }
  if ($Found[$Text].Count -lt 3) { [void]$Found[$Text].Add($Ref) }
}

$TokRx = [regex]"'(?:[^']|'')*'|#\$[0-9A-Fa-f]+|#\d+|//[^\r\n]*|\{[^}]*\}|\(\*[\s\S]*?\*\)|[A-Za-z_][A-Za-z0-9_]*|\d+|:=|<>|<=|>=|\S"

function Get-Tokens([string]$Src) {
  $Lines = New-Object System.Collections.Generic.List[int]
  $Lines.Add(0)
  for ($i = 0; $i -lt $Src.Length; $i++) { if ($Src[$i] -eq "`n") { $Lines.Add($i + 1) } }
  $Toks = New-Object System.Collections.Generic.List[object]
  foreach ($M in $TokRx.Matches($Src)) {
    $V = $M.Value
    if ($V.StartsWith('//') -or $V.StartsWith('{') -or $V.StartsWith('(*')) { continue }
    $Idx = $Lines.BinarySearch($M.Index)
    if ($Idx -lt 0) { $Idx = (-bnot $Idx) - 1 }
    if ($V.StartsWith("'")) {
      $Toks.Add(@{ K = 's'; V = $V.Substring(1, $V.Length - 2).Replace("''", "'"); L = $Idx + 1 })
    } elseif ($V.StartsWith('#')) {
      if ($V.StartsWith('#$')) { $C = [Convert]::ToInt32($V.Substring(2), 16) } else { $C = [int]$V.Substring(1) }
      $Toks.Add(@{ K = 's'; V = [string][char]$C; L = $Idx + 1 })
    } elseif ($V -match '^[A-Za-z_]') {
      $Toks.Add(@{ K = 'i'; V = $V.ToLower(); L = $Idx + 1 })
    } else {
      $Toks.Add(@{ K = 'p'; V = $V; L = $Idx + 1 })
    }
  }
  return ,$Toks
}

# teksten (aaneengesloten met +) in tokens [A, B)
function Add-Strings($T, [int]$A, [int]$B, [string]$File) {
  $Cur = $null; $Line = 0
  for ($i = $A; $i -lt $B; $i++) {
    $X = $T[$i]
    if ($X.K -eq 's') {
      if ($null -eq $Cur) { $Cur = ''; $Line = $X.L }
      $Cur += $X.V
    } elseif ($X.K -eq 'p' -and $X.V -eq '+' -and $null -ne $Cur -and ($i + 1) -lt $B -and $T[$i + 1].K -eq 's') {
      continue
    } else {
      if ($null -ne $Cur) { Add-Msg $Cur "$($File):$Line"; $Cur = $null }
    }
  }
  if ($null -ne $Cur) { Add-Msg $Cur "$($File):$Line" }
}

# einde van de opdracht die bij token A begint (begin..end of tot ; / else)
function Get-StmtEnd($T, [int]$A, [bool]$StopAtElse = $false) {
  $Depth = 0; $Par = 0
  for ($i = $A; $i -lt $T.Count; $i++) {
    $X = $T[$i]
    if ($X.K -eq 'i') {
      if ($X.V -eq 'begin' -or $X.V -eq 'case' -or $X.V -eq 'try') { $Depth++ }
      elseif ($X.V -eq 'end') { $Depth--; if ($Depth -le 0) { return $i + 1 } }
      elseif ($StopAtElse -and $Depth -eq 0 -and $Par -eq 0 -and $X.V -eq 'else') { return $i }
    } elseif ($X.K -eq 'p') {
      if ($X.V -eq '(') { $Par++ } elseif ($X.V -eq ')') { $Par-- }
      elseif ($X.V -eq ';' -and $Depth -eq 0 -and $Par -eq 0) { return $i }
    }
  }
  return $T.Count
}

$LangLabels = 'lgdutch', 'lgfrench', 'lggerman', 'stdutch', 'stfrench', 'stgerman'

foreach ($F in $Files) {
  $Rel = $F.Name
  $T = Get-Tokens ([IO.File]::ReadAllText($F.FullName, $Utf8))
  $N = $T.Count
  $LastCond = ''
  for ($i = 0; $i -lt $N; $i++) {
    $X = $T[$i]

    # Tr(...) / MyTr / TrHelp: 5 argumenten, Engels = 3e; T(...): 4, Engels = 2e;
    # LangTr(...) / PoTr(...): 1 argument
    if ($X.K -eq 'i' -and ($X.V -eq 'tr' -or $X.V -eq 'mytr' -or $X.V -eq 'trhelp' -or $X.V -eq 't' -or $X.V -eq 'langtr' -or $X.V -eq 'potr') -and
        ($i + 1) -lt $N -and $T[$i + 1].V -eq '(') {
      $CallArgs = @(); $Start = $i + 2; $Par = 0
      for ($j = $i + 2; $j -lt $N; $j++) {
        $Y = $T[$j]
        if ($Y.K -eq 'p' -and ($Y.V -eq '(' -or $Y.V -eq '[')) { $Par++ }
        elseif ($Y.K -eq 'p' -and ($Y.V -eq ')' -or $Y.V -eq ']')) {
          if ($Par -eq 0) { $CallArgs += ,@($Start, $j); break }
          $Par--
        }
        elseif ($Y.K -eq 'p' -and $Y.V -eq ',' -and $Par -eq 0) { $CallArgs += ,@($Start, $j); $Start = $j + 1 }
      }
      $Want = -1
      if ($X.V -eq 't' -and $CallArgs.Count -eq 4) { $Want = 1 }
      elseif (($X.V -eq 'langtr' -or $X.V -eq 'potr') -and $CallArgs.Count -eq 1) { $Want = 0 }
      elseif ($X.V -ne 't' -and $CallArgs.Count -eq 5) { $Want = 2 }
      if ($Want -ge 0) { Add-Strings $T $CallArgs[$Want][0] $CallArgs[$Want][1] $Rel }
      continue
    }

    # lgEnglish: / stEnglish:  (ook chatgridpcodeSmall.lgEnglish:)
    if ($X.K -eq 'i' -and ($X.V -eq 'lgenglish' -or $X.V -eq 'stenglish') -and ($i + 1) -lt $N -and $T[$i + 1].V -eq ':') {
      $E = Get-StmtEnd $T ($i + 2)
      Add-Strings $T ($i + 2) $E $Rel
      continue
    }

    # if FBoxTaal = stEnglish then ... / if Language = lgEnglish then ...
    if ($X.K -eq 'i' -and ($X.V -eq 'lgenglish' -or $X.V -eq 'stenglish') -and ($i + 1) -lt $N -and
        $T[$i + 1].V -eq 'then' -and $i -gt 0 -and $T[$i - 1].V -eq '=') {
      $E = Get-StmtEnd $T ($i + 2) $true
      Add-Strings $T ($i + 2) $E $Rel
      continue
    }

    # ...KeyData[lgEnglish].Values[..] := '...' (kolomkoppen van de instellingen)
    if ($X.K -eq 'i' -and $X.V -eq 'lgenglish' -and ($i + 1) -lt $N -and $T[$i + 1].V -eq ']') {
      $E = Get-StmtEnd $T ($i + 2)
      Add-Strings $T ($i + 2) $E $Rel
      continue
    }

    # case Taal.ItemIndex of / case TaalIndex of ... 1: (Engels)
    if ($X.K -eq 'i' -and $X.V -eq 'case' -and ($i + 4) -lt $N -and
        (($T[$i + 1].V -eq 'taal' -and $T[$i + 3].V -eq 'itemindex' -and $T[$i + 4].V -eq 'of') -or
         ($T[$i + 1].V -eq 'taalindex' -and $T[$i + 2].V -eq 'of'))) {
      $Depth = 0
      for ($j = $i + 1; $j -lt $N; $j++) {
        $Y = $T[$j]
        if ($Y.K -eq 'i' -and ($Y.V -eq 'begin' -or $Y.V -eq 'case')) { $Depth++ }
        elseif ($Y.K -eq 'i' -and $Y.V -eq 'end') { if ($Depth -eq 0) { break }; $Depth-- }
        elseif ($Depth -eq 0 -and $Y.V -eq '1' -and ($j + 1) -lt $N -and $T[$j + 1].V -eq ':') {
          $E = Get-StmtEnd $T ($j + 2)
          Add-Strings $T ($j + 2) $E $Rel
          break
        }
      }
      continue
    }

    # ('NL', 'EN', 'FR', 'DE') in een tabel met vier talen, bv. de namen van
    # de ingebouwde panelen in main.pas: Engels = 2e
    if ($X.K -eq 'p' -and $X.V -eq '(' -and ($i + 8) -lt $N -and
        $T[$i + 1].K -eq 's' -and $T[$i + 2].V -eq ',' -and $T[$i + 3].K -eq 's' -and $T[$i + 4].V -eq ',' -and
        $T[$i + 5].K -eq 's' -and $T[$i + 6].V -eq ',' -and $T[$i + 7].K -eq 's' -and $T[$i + 8].V -eq ')' -and
        $i -gt 0 -and $T[$i - 1].K -eq 'p' -and ($T[$i - 1].V -eq '(' -or $T[$i - 1].V -eq ',')) {
      Add-Msg $T[$i + 3].V "$($Rel):$($T[$i + 3].L)"
      continue
    }

    # if BTaal = 'XX' then ...  (keten per taal)
    if ($X.K -eq 'p' -and $X.V -eq '=' -and ($i + 2) -lt $N -and $T[$i + 1].K -eq 's' -and
        $T[$i + 1].V -match '^(NL|ENG|FR|DU)$' -and $T[$i + 2].V -eq 'then') {
      $Lang = $T[$i + 1].V
      if ($Lang -eq 'NL') { $Chain = @{} }
      if ($null -eq $Chain) { $Chain = @{} }
      $Chain[$Lang] = $true
      $LastCond = $Lang
      if ($Lang -eq 'ENG') {
        $E = Get-StmtEnd $T ($i + 3) $true
        Add-Strings $T ($i + 3) $E $Rel
      }
      continue
    }
    # ... else <Engels>  (na NL/FR/DU zonder eigen ENG-tak)
    if ($X.K -eq 'i' -and $X.V -eq 'else' -and $LastCond -ne '' -and $LastCond -ne 'ENG' -and
        ($i + 1) -lt $N -and $T[$i + 1].V -ne 'if' -and $null -ne $Chain -and -not $Chain.ContainsKey('ENG') -and
        $Chain.Count -ge 2) {
      $E = Get-StmtEnd $T ($i + 1)
      Add-Strings $T ($i + 1) $E $Rel
      $LastCond = ''
      continue
    }  }
}

# teksten die de regels hierboven niet vinden
Add-Msg 'Settings' 'main.pas (moduscurrent, statusbalk)'
Add-Msg 'lock' 'janSimLogic.pas (rechtsklikmenu)'

# namen in de instellingen: [lgEnglish] van StringHolderTranslations (hex)
$Lfm = Join-Path $Project 'fsettings.lfm'
if (Test-Path $Lfm) {
  $Txt = [IO.File]::ReadAllText($Lfm, $Utf8)
  $M = [regex]::Match($Txt, 'object StringHolderTranslations[\s\S]*?StrData = \(([\s\S]*?)\)')
  if ($M.Success) {
    $Section = ''
    foreach ($H in [regex]::Matches($M.Groups[1].Value, "'([0-9a-fA-F]*)'")) {
      $Hex = $H.Groups[1].Value
      $Bytes = New-Object byte[] ($Hex.Length / 2)
      for ($k = 0; $k -lt $Bytes.Length; $k++) { $Bytes[$k] = [Convert]::ToByte($Hex.Substring($k * 2, 2), 16) }
      $Line = $Utf8.GetString($Bytes)
      if ($Line -match '^\[(.+)\]$') { $Section = $Matches[1]; continue }
      if ($Section -eq 'lgEnglish' -and $Line -match '^[^=]+=(.+)$') { Add-Msg $Matches[1] 'fsettings.lfm' }
    }
  }
}

function Esc([string]$S) {
  return $S.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", '\n').Replace("`t", '\t')
}

New-Item -ItemType Directory -Force $LangDir | Out-Null
$Out = New-Object System.Text.StringBuilder
[void]$Out.AppendLine('# Logic - sjabloon voor vertalingen (gemaakt door tools/make-pot.ps1)')
[void]$Out.AppendLine('# Vertaal met Poedit: maak een nieuwe vertaling van dit bestand en bewaar')
[void]$Out.AppendLine('# ze als <code>.po in de map lang (bv. it.po voor Italiaans).')
[void]$Out.AppendLine('msgid ""')
[void]$Out.AppendLine('msgstr ""')
[void]$Out.AppendLine('"Content-Type: text/plain; charset=UTF-8\n"')
[void]$Out.AppendLine('"Project-Id-Version: Logic\n"')
[void]$Out.AppendLine('')
foreach ($K in $Found.Keys) {
  [void]$Out.AppendLine('#: ' + ($Found[$K] -join ' '))
  [void]$Out.AppendLine('msgid "' + (Esc $K) + '"')
  [void]$Out.AppendLine('msgstr ""')
  [void]$Out.AppendLine('')
}
$Pot = Join-Path $LangDir 'logic.pot'
[IO.File]::WriteAllText($Pot, $Out.ToString(), $Utf8)
Write-Host ("logic.pot: {0} teksten" -f $Found.Count)

if ($Merge) {
  foreach ($Po in Get-ChildItem $LangDir -Filter *.po) {
    $Txt = [IO.File]::ReadAllText($Po.FullName, $Utf8)
    $Have = New-Object System.Collections.Hashtable([StringComparer]::Ordinal)
    foreach ($M in [regex]::Matches($Txt, '(?m)^msgid "(.*)"\r?$((?:\r?\n".*"\r?$)*)')) {
      $Id = $M.Groups[1].Value + (($M.Groups[2].Value -split "`n" | ForEach-Object { $_.Trim() } |
             Where-Object { $_ -ne '' } | ForEach-Object { $_.Substring(1, $_.Length - 2) }) -join '')
      $Have[$Id] = $true
    }
    $Add = New-Object System.Text.StringBuilder
    $Count = 0
    foreach ($K in $Found.Keys) {
      $E = Esc $K
      if (-not $Have.ContainsKey($E)) {
        [void]$Add.Append('' + "`n")
        [void]$Add.Append('msgid "' + $E + '"' + "`n")
        [void]$Add.Append('msgstr ""' + "`n")
        $Count++
      }
    }
    if ($Count -gt 0) { [IO.File]::AppendAllText($Po.FullName, $Add.ToString(), $Utf8) }
    Write-Host ("{0}: {1} nieuwe teksten" -f $Po.Name, $Count)
  }
}
