<#
    Paruosia nuotraukas ir sugeneruoja STATINI galeriju HTML tiesiai i index.html.

    IDEDI:      photos\_originalai\<Galerija>\*.jpg
                photos\_originalai\<Galerija>\pavadinimai.txt   failas.jpg = Antraste
                photos\_originalai\<Galerija>\alt.txt           failas.jpg = alt tekstas
                photos\_originalai\atranka.txt                  geriausiu nuotrauku sarasas

    GAUNI:      photos\full\   2560 px
                photos\thumb\   700 px
                index.html      galerijos tarp GALLERY:START ir GALLERY:END

    Paleidimas: powershell -ExecutionPolicy Bypass -File tools\paruosti-nuotraukas.ps1
#>

param([int]$FullDydis = 2000, [int]$ThumbDydis = 700, [int]$Kokybe = 80)

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

$saknis     = Split-Path -Parent $PSScriptRoot
$originalai = Join-Path $saknis "photos\_originalai"
$full       = Join-Path $saknis "photos\full"
$thumb      = Join-Path $saknis "photos\thumb"

# Sekciju tvarka, antrastes ir paaiskinimai
$SEKCIJOS = @(
  @{ id="selected"; vardas=$null;      h2="Selected work";               tekstas="Twenty frames I would show first." }
  @{ id="travel";   vardas="Travel";   h2="Travel photography";          tekstas="Roads, cities and coastlines - from the medinas of Marrakech to Death Valley." }
  @{ id="wildlife"; vardas="Wildlife"; h2="Wildlife photography";        tekstas="Tanzania: patience, distance, and light you cannot plan for." }
  @{ id="people";   vardas="People";   h2="People and street photography"; tekstas="Portraits and moments that happened by themselves." }
)

$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$par = New-Object System.Drawing.Imaging.EncoderParameters(1)
$par.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Kokybe)

function TaisykOrientacija {
    param($Img)
    if ($Img.PropertyIdList -notcontains 274) { return }
    switch ($Img.GetPropertyItem(274).Value[0]) {
        2 { $Img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
        3 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        4 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
        5 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
        6 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        7 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
        8 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }
}

function Sumazink {
    param($Img, [string]$Isvestis, [int]$Riba)
    $m = [Math]::Min($Riba / $Img.Width, $Riba / $Img.Height)
    if ($m -gt 1) { $m = 1 }
    $nw = [int][Math]::Round($Img.Width * $m); $nh = [int][Math]::Round($Img.Height * $m)
    $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
    try {
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.DrawImage($Img, 0, 0, $nw, $nh)
        } finally { $g.Dispose() }
        $bmp.Save($Isvestis, $enc, $par)
    } finally { $bmp.Dispose() }
    return @($nw, $nh)
}

function SkaitykPoras {
    param([string]$Kelias)
    $h = @{}
    if (Test-Path -LiteralPath $Kelias) {
        Get-Content -LiteralPath $Kelias -Encoding UTF8 | ForEach-Object {
            $e = $_.Trim()
            if ($e -and -not $e.StartsWith("#") -and $e.Contains("=")) {
                $i = $e.IndexOf("=")
                $h[$e.Substring(0,$i).Trim()] = $e.Substring($i+1).Trim()
            }
        }
    }
    return $h
}

function UrlKelias { param([string]$K) return (($K.Split([char]92) | ForEach-Object { [Uri]::EscapeDataString($_) }) -join "/") }
function Htm { param([string]$T) return [System.Net.WebUtility]::HtmlEncode($T) }

# --- atranka ---
$atrankaNr = @{}
$af = Join-Path $originalai "atranka.txt"
if (Test-Path -LiteralPath $af) {
    $nr = 0
    Get-Content -LiteralPath $af -Encoding UTF8 | ForEach-Object {
        $e = $_.Trim()
        if ($e -and -not $e.StartsWith("#")) { $atrankaNr[$e] = $nr; $nr++ }
    }
}

# --- apdorojam nuotraukas ---
$visos = @()
$nauji = 0; $praleisti = 0

$galerijos = Get-ChildItem -Path $originalai -Directory | Where-Object { $_.Name -notlike "_*" }
foreach ($gal in $galerijos) {
    $antrastes = SkaitykPoras (Join-Path $gal.FullName "pavadinimai.txt")
    $altai     = SkaitykPoras (Join-Path $gal.FullName "alt.txt")

    $failai = Get-ChildItem -Path $gal.FullName -File |
              Where-Object { $_.Extension -match '^[.](jpg|jpeg)$' } | Sort-Object Name

    foreach ($f in $failai) {
        $rel = Join-Path $gal.Name ([System.IO.Path]::ChangeExtension($f.Name, ".jpg"))
        $fk = Join-Path $full $rel; $tk = Join-Path $thumb $rel
        foreach ($d in @((Split-Path $fk -Parent), (Split-Path $tk -Parent))) {
            if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        }

        $reikia = -not ((Test-Path $fk) -and (Test-Path $tk) -and ((Get-Item $fk).LastWriteTime -ge $f.LastWriteTime))
        if ($reikia) {
            $img = [System.Drawing.Image]::FromFile($f.FullName)
            try {
                TaisykOrientacija -Img $img
                $null = Sumazink -Img $img -Isvestis $fk -Riba $FullDydis
                $null = Sumazink -Img $img -Isvestis $tk -Riba $ThumbDydis
            } finally { $img.Dispose() }
            $nauji++
            Write-Host ("  + {0}" -f $rel)
        } else { $praleisti++ }

        $ti = [System.Drawing.Image]::FromFile($tk)
        try { $tw = $ti.Width; $th = $ti.Height } finally { $ti.Dispose() }

        $visos += [pscustomobject]@{
            Galerija = $gal.Name
            Failas   = $f.Name
            Full     = "photos/full/"  + (UrlKelias $rel)
            Thumb    = "photos/thumb/" + (UrlKelias $rel)
            Antraste = $(if ($antrastes.ContainsKey($f.Name)) { $antrastes[$f.Name] } else { "" })
            Alt      = $(if ($altai.ContainsKey($f.Name)) { $altai[$f.Name] } else { "TODO: describe this photograph" })
            W        = $tw
            H        = $th
            AtrNr    = $(if ($atrankaNr.ContainsKey($f.Name)) { $atrankaNr[$f.Name] } else { -1 })
        }
    }
}

# --- statinis HTML ---
$sb = New-Object System.Text.StringBuilder
$eilNr = 0
$viso = $visos.Count

foreach ($s in $SEKCIJOS) {
    if ($s.id -eq "selected") {
        $grupe = @($visos | Where-Object { $_.AtrNr -ge 0 } | Sort-Object AtrNr)
        $kiekis = "{0} of {1} photographs" -f $grupe.Count, $viso
    } else {
        $grupe = @($visos | Where-Object { $_.Galerija -eq $s.vardas })
        $kiekis = "{0} photograph{1}" -f $grupe.Count, $(if ($grupe.Count -eq 1) { "" } else { "s" })
    }
    if ($grupe.Count -eq 0) { continue }

    [void]$sb.AppendLine("<section class=""sekcija"" id=""$($s.id)"">")
    [void]$sb.AppendLine("  <div class=""sekcija__juosta"">")
    [void]$sb.AppendLine("    <h2>$(Htm $s.h2)</h2>")
    [void]$sb.AppendLine("    <p>$(Htm $s.tekstas)</p>")
    [void]$sb.AppendLine("    <span class=""sekcija__kiekis"">$kiekis</span>")
    [void]$sb.AppendLine("    <div class=""lankas""></div>")
    [void]$sb.AppendLine("  </div>")
    [void]$sb.AppendLine("  <div class=""galerija"">")

    foreach ($p in $grupe) {
        $eilNr++
        $kr = if ($eilNr -le 2) { ' loading="eager" fetchpriority="high"' } else { ' loading="lazy"' }
        [void]$sb.AppendLine("    <figure class=""tile"" tabindex=""0"" data-full=""$($p.Full)"">")
        [void]$sb.AppendLine("      <img src=""$($p.Thumb)"" alt=""$(Htm $p.Alt)"" width=""$($p.W)"" height=""$($p.H)""$kr decoding=""async"">")
        if ($p.Antraste) { [void]$sb.AppendLine("      <figcaption>$(Htm $p.Antraste)</figcaption>") }
        [void]$sb.AppendLine("    </figure>")
    }

    [void]$sb.AppendLine("  </div>")
    [void]$sb.AppendLine("</section>")
}

# --- iterpiam i index.html ---
$ix = Join-Path $saknis "index.html"
$h = [System.IO.File]::ReadAllText($ix)
$pr = "<!-- GALLERY:START -->"; $pb = "<!-- GALLERY:END -->"
$i = $h.IndexOf($pr); $j = $h.IndexOf($pb)
if ($i -lt 0 -or $j -lt 0) { throw "index.html truksta zymes $pr / $pb" }
$naujas = $h.Substring(0, $i + $pr.Length) + "`r`n" + $sb.ToString() + $h.Substring($j)
[System.IO.File]::WriteAllText($ix, $naujas, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "-------------------------------------------"
Write-Host ("Nuotrauku:   {0}" -f $viso)
Write-Host ("Apdorota:    {0} nauju, {1} praleista" -f $nauji, $praleisti)
Write-Host ("Be alt teksto: {0}" -f (@($visos | Where-Object { $_.Alt -like "TODO*" }).Count))
Write-Host ("index.html:  galerijos iterptos")
Write-Host "-------------------------------------------"