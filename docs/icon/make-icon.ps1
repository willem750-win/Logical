param([string]$OutDir)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

function New-Png([int]$size) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.PixelOffsetMode = 'HighQuality'
  $g.Clear([System.Drawing.Color]::Transparent)
  $k = $size / 256.0
  $g.ScaleTransform($k, $k)
  # op kleine formaten lijnen relatief dikker maken
  $t = if ($size -le 16) { 1.6 } elseif ($size -le 24) { 1.4 } elseif ($size -le 32) { 1.25 } elseif ($size -le 48) { 1.1 } else { 1.0 }
  $line = 16.0 * $t
  $outline = 12.0 * $t

  # achtergrond: afgeronde blauwe tegel
  $r = 52; $x0 = 8; $y0 = 8; $w = 240
  $bg = New-Object System.Drawing.Drawing2D.GraphicsPath
  $bg.AddArc($x0, $y0, $r, $r, 180, 90)
  $bg.AddArc($x0 + $w - $r, $y0, $r, $r, 270, 90)
  $bg.AddArc($x0 + $w - $r, $y0 + $w - $r, $r, $r, 0, 90)
  $bg.AddArc($x0, $y0 + $w - $r, $r, $r, 90, 90)
  $bg.CloseFigure()
  $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Point(0, 8)), (New-Object System.Drawing.Point(0, 248)),
    [System.Drawing.Color]::FromArgb(255, 58, 124, 230), [System.Drawing.Color]::FromArgb(255, 22, 52, 140))
  $g.FillPath($grad, $bg)

  $dark = [System.Drawing.Color]::FromArgb(255, 20, 30, 60)
  $penLine = New-Object System.Drawing.Pen([System.Drawing.Color]::White, [single]$line)
  $penLine.StartCap = 'Round'; $penLine.EndCap = 'Round'

  # draden: twee ingangen en een uitgang
  $g.DrawLine($penLine, 46, 104, 96, 104)
  $g.DrawLine($penLine, 46, 152, 96, 152)
  $g.DrawLine($penLine, 176, 128, 210, 128)

  # EN-poort: rechte linkerkant, halve cirkel rechts
  $gate = New-Object System.Drawing.Drawing2D.GraphicsPath
  $gate.AddLine(124, 76, 96, 76)
  $gate.AddLine(96, 76, 96, 180)
  $gate.AddLine(96, 180, 124, 180)
  $gate.AddArc(72, 76, 104, 104, 90, -180)
  $gate.CloseFigure()
  $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 240, 140))), $gate)
  $penGate = New-Object System.Drawing.Pen($dark, [single]$outline)
  $penGate.LineJoin = 'Round'
  $g.DrawPath($penGate, $gate)

  # aansluitpunten: groen = ingang aan, rood = uitgang
  $dot = 36.0 * [Math]::Min($t, 1.3)
  $penDot = New-Object System.Drawing.Pen($dark, [single](7.0 * $t))
  $green = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 46, 204, 64))
  $red   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 235, 50, 50))
  foreach ($c in @(@(44, 104, $green), @(44, 152, $green), @(212, 128, $red))) {
    $cx = $c[0]; $cy = $c[1]
    $g.FillEllipse($c[2], $cx - $dot / 2, $cy - $dot / 2, $dot, $dot)
    $g.DrawEllipse($penDot, $cx - $dot / 2, $cy - $dot / 2, $dot, $dot)
  }
  $g.Dispose()
  return $bmp
}

# 32-bit DIB-entry (voor kleine formaten; maximaal compatibel)
function Get-DibBytes($bmp) {
  $s = $bmp.Width
  $ms = New-Object IO.MemoryStream
  $bw = New-Object IO.BinaryWriter($ms)
  $bw.Write([int]40); $bw.Write([int]$s); $bw.Write([int]($s * 2))
  $bw.Write([int16]1); $bw.Write([int16]32); $bw.Write([int]0)
  $bw.Write([int]0); $bw.Write([int]0); $bw.Write([int]0); $bw.Write([int]0); $bw.Write([int]0)
  for ($y = $s - 1; $y -ge 0; $y--) {
    for ($x = 0; $x -lt $s; $x++) {
      $p = $bmp.GetPixel($x, $y)
      $bw.Write([byte]$p.B); $bw.Write([byte]$p.G); $bw.Write([byte]$p.R); $bw.Write([byte]$p.A)
    }
  }
  $maskRow = [int]([Math]::Ceiling($s / 32.0) * 4)
  for ($y = $s - 1; $y -ge 0; $y--) {
    $row = New-Object byte[] $maskRow
    for ($x = 0; $x -lt $s; $x++) {
      if ($bmp.GetPixel($x, $y).A -eq 0) { $row[[int][Math]::Floor($x / 8)] = $row[[int][Math]::Floor($x / 8)] -bor (0x80 -shr ($x % 8)) }
    }
    $bw.Write($row)
  }
  $bw.Flush(); return $ms.ToArray()
}

$sizes = 16, 24, 32, 48, 64, 128, 256
$entries = @()
foreach ($s in $sizes) {
  $bmp = New-Png $s
  if ($s -ge 256) {
    $ms = New-Object IO.MemoryStream; $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); $data = $ms.ToArray()
  } else { $data = Get-DibBytes $bmp }
  $entries += ,@($s, $data)
  if ($s -eq 256) { $bmp.Save((Join-Path $OutDir 'logic-256.png'), [System.Drawing.Imaging.ImageFormat]::Png) }
  $bmp.Dispose()
}
$big = New-Png 512; $big.Save((Join-Path $OutDir 'logic-512.png'), [System.Drawing.Imaging.ImageFormat]::Png); $big.Dispose()

$fs = [IO.File]::Create((Join-Path $OutDir 'logic.ico'))
$bw = New-Object IO.BinaryWriter($fs)
$bw.Write([int16]0); $bw.Write([int16]1); $bw.Write([int16]$entries.Count)
$offset = 6 + 16 * $entries.Count
foreach ($e in $entries) {
  $s = $e[0]; $d = $e[1]
  $b = if ($s -ge 256) { 0 } else { $s }
  $bw.Write([byte]$b); $bw.Write([byte]$b); $bw.Write([byte]0); $bw.Write([byte]0)
  $bw.Write([int16]1); $bw.Write([int16]32); $bw.Write([int]$d.Length); $bw.Write([int]$offset)
  $offset += $d.Length
}
foreach ($e in $entries) { $bw.Write([byte[]]$e[1]) }
$bw.Close()
"ok"


