<#
    Paruosia nuotraukas ir sugeneruoja STATINI galeriju HTML i visus puslapius.

    IDEDI:      photos\_originalai\<Galerija>\*.jpg
                photos\_originalai\<Galerija>\alt.txt   failas.jpg = alt tekstas
                photos\puslapiai.txt                    kas i kuri puslapi patenka

    GAUNI:      photos\full\     2000 px
                photos\thumb\     700 px
                photos\thumb-sm\  400 px  (srcset - telefonams ir ne-retina ekranams)
                index.html, tanzania.html, morocco.html, elsewhere.html
                                  galerijos tarp GALLERY:START ir GALLERY:END

    SVARBU:     Skriptas keicia TIK tarpa tarp GALLERY:START ir GALLERY:END.
                Antraste, hero nuotrauka, "About" ir kita puslapiu dalis
                redaguojama ranka - jos skriptas neliecia.

    Paleidimas: powershell -ExecutionPolicy Bypass -File tools\paruosti-nuotraukas.ps1
#>

param([int]$FullDydis = 2000, [int]$ThumbDydis = 700, [int]$ThumbSmDydis = 400, [int]$Kokybe = 80)

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

$saknis     = Split-Path -Parent $PSScriptRoot
$originalai = Join-Path $saknis "photos\_originalai"
$full       = Join-Path $saknis "photos\full"
$thumb      = Join-Path $saknis "photos\thumb"
$thumbSm    = Join-Path $saknis "photos\thumb-sm"
$manifestas = Join-Path $saknis "photos\puslapiai.txt"

# sizes: titulinio atranka desktope 3 stulpeliai, darbu puslapiai - 4
$SIZES_ATRANKA = "(max-width:620px) 100vw, (max-width:900px) 50vw, (max-width:1220px) 33vw, 380px"
$SIZES_KITA    = "(max-width:620px) 50vw, (max-width:900px) 50vw, (max-width:1200px) 33vw, 350px"

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

# =====================================================================
#  1. Nuotrauku apdorojimas
# =====================================================================
$nuotraukos = @{}          # "Galerija/failas.jpg" -> info
$nauji = 0; $praleisti = 0

$galerijos = Get-ChildItem -Path $originalai -Directory | Where-Object { $_.Name -notlike "_*" }
foreach ($gal in $galerijos) {
    $altai = SkaitykPoras (Join-Path $gal.FullName "alt.txt")

    $failai = Get-ChildItem -Path $gal.FullName -File |
              Where-Object { $_.Extension -match '^[.](jpg|jpeg)$' } | Sort-Object Name

    foreach ($f in $failai) {
        $rel = Join-Path $gal.Name ([System.IO.Path]::ChangeExtension($f.Name, ".jpg"))
        $fk = Join-Path $full $rel; $tk = Join-Path $thumb $rel; $sk = Join-Path $thumbSm $rel
        foreach ($d in @((Split-Path $fk -Parent), (Split-Path $tk -Parent), (Split-Path $sk -Parent))) {
            if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        }

        $reikia = -not ((Test-Path $fk) -and (Test-Path $tk) -and (Test-Path $sk) -and ((Get-Item $fk).LastWriteTime -ge $f.LastWriteTime))
        if ($reikia) {
            $img = [System.Drawing.Image]::FromFile($f.FullName)
            try {
                TaisykOrientacija -Img $img
                $null = Sumazink -Img $img -Isvestis $fk -Riba $FullDydis
                $null = Sumazink -Img $img -Isvestis $tk -Riba $ThumbDydis
                $null = Sumazink -Img $img -Isvestis $sk -Riba $ThumbSmDydis
            } finally { $img.Dispose() }
            $nauji++
            Write-Host ("  + {0}" -f $rel)
        } else { $praleisti++ }

        $ti = [System.Drawing.Image]::FromFile($tk)
        try { $tw = $ti.Width; $th = $ti.Height } finally { $ti.Dispose() }

        $raktas = ($gal.Name + "/" + [System.IO.Path]::ChangeExtension($f.Name, ".jpg"))
        $nuotraukos[$raktas] = [pscustomobject]@{
            Raktas   = $raktas
            Full     = "photos/full/"     + (UrlKelias $rel)
            Thumb    = "photos/thumb/"    + (UrlKelias $rel)
            ThumbSm  = "photos/thumb-sm/" + (UrlKelias $rel)
            Alt      = $(if ($altai.ContainsKey($f.Name)) { $altai[$f.Name] } else { "TODO: describe this photograph" })
            W        = $tw
            H        = $th
        }
    }
}

# =====================================================================
#  2. Manifestas: kas i kuri puslapi patenka
# =====================================================================
if (-not (Test-Path -LiteralPath $manifestas)) { throw "Nerasta $manifestas" }

$puslapiai = New-Object System.Collections.ArrayList
$dabar = $null
foreach ($eil in (Get-Content -LiteralPath $manifestas -Encoding UTF8)) {
    $e = $eil.Trim()
    if (-not $e -or $e.StartsWith("#")) { continue }

    if ($e.StartsWith("==")) {
        $d = $e.Substring(2).Split("|")
        if ($d.Count -lt 4) { throw "Bloga puslapio eilute: $e" }
        $dabar = [pscustomobject]@{
            Id      = $d[0].Trim()
            Failas  = $d[1].Trim()
            Vardas  = $d[2].Trim()
            Tekstas = ($d[3..($d.Count-1)] -join "|").Trim()
            Kadrai  = New-Object System.Collections.ArrayList
        }
        [void]$puslapiai.Add($dabar)
        continue
    }

    if ($null -eq $dabar) { throw "Nuotrauka pries puslapio eilute: $e" }
    $d = $e.Split("|")
    $raktas = $d[0].Trim()
    if (-not $nuotraukos.ContainsKey($raktas)) {
        Write-Warning ("Manifeste yra, bet nuotraukos nerasta: {0}" -f $raktas)
        continue
    }
    [void]$dabar.Kadrai.Add([pscustomobject]@{
        Raktas     = $raktas
        Pavadinimas= $(if ($d.Count -gt 1) { $d[1].Trim() } else { "" })
        Vieta      = $(if ($d.Count -gt 2) { $d[2].Trim() } else { "" })
    })
}

$atranka   = $puslapiai | Where-Object { $_.Id -eq "selected" } | Select-Object -First 1
$kunai     = @($puslapiai | Where-Object { $_.Id -ne "selected" })
if ($null -eq $atranka) { throw "Manifeste truksta sekcijos '== selected'" }

# Titulinio atrankai pavadinimai imami is to puslapio, kur nuotrauka aprasyta
$pavadinimai = @{}
$vietos      = @{}
foreach ($p in $kunai) {
    foreach ($k in $p.Kadrai) {
        if ($k.Pavadinimas) { $pavadinimai[$k.Raktas] = $k.Pavadinimas }
        if ($k.Vieta)       { $vietos[$k.Raktas]      = $k.Vieta }
    }
}

# =====================================================================
#  3. HTML
# =====================================================================
function Plytele {
    param($Kadras, [string]$Sizes, [bool]$Pirmas)
    $n = $nuotraukos[$Kadras.Raktas]
    $pav = $(if ($Kadras.Pavadinimas) { $Kadras.Pavadinimas }
             elseif ($pavadinimai.ContainsKey($Kadras.Raktas)) { $pavadinimai[$Kadras.Raktas] } else { "" })
    $vie = $(if ($Kadras.Vieta) { $Kadras.Vieta }
             elseif ($vietos.ContainsKey($Kadras.Raktas)) { $vietos[$Kadras.Raktas] } else { "" })
    $kr = $(if ($Pirmas) { ' loading="eager" fetchpriority="high"' } else { ' loading="lazy"' })
    $dv = $(if ($vie) { ' data-vieta="' + (Htm $vie) + '"' } else { "" })

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('    <figure class="tile" role="button" tabindex="0" data-full="' + $n.Full + '"' + $dv + '>')
    [void]$sb.AppendLine('      <img src="' + $n.Thumb + '" srcset="' + $n.ThumbSm + ' 400w, ' + $n.Thumb + ' 700w" sizes="' + $Sizes + '" alt="' + (Htm $n.Alt) + '" width="' + $n.W + '" height="' + $n.H + '"' + $kr + ' decoding="async">')
    if ($pav) { [void]$sb.AppendLine('      <figcaption>' + (Htm $pav) + '</figcaption>') }
    [void]$sb.AppendLine('    </figure>')
    return $sb.ToString()
}

function Galerija {
    param($Kadrai, [string]$Sizes)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('  <div class="galerija">')
    for ($i = 0; $i -lt $Kadrai.Count; $i++) {
        [void]$sb.Append((Plytele -Kadras $Kadrai[$i] -Sizes $Sizes -Pirmas ($i -lt 2)))
    }
    [void]$sb.AppendLine('  </div>')
    return $sb.ToString()
}

function IterpkI {
    param([string]$Failas, [string]$Turinys)
    $kelias = Join-Path $saknis $Failas
    if (-not (Test-Path -LiteralPath $kelias)) { throw "Nerastas puslapis $Failas" }
    $h = [System.IO.File]::ReadAllText($kelias)
    $pr = "<!-- GALLERY:START -->"; $pb = "<!-- GALLERY:END -->"
    $i = $h.IndexOf($pr); $j = $h.IndexOf($pb)
    if ($i -lt 0 -or $j -lt 0) { throw "$Failas truksta zymes $pr / $pb" }
    $naujas = $h.Substring(0, $i + $pr.Length) + "`r`n" + $Turinys + $h.Substring($j)
    [System.IO.File]::WriteAllText($kelias, $naujas, (New-Object System.Text.UTF8Encoding($false)))
}

# --- darbu puslapiai ---
foreach ($p in $kunai) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<section class="sekcija" id="' + $p.Id + '">')
    [void]$sb.AppendLine('  <div class="sekcija__juosta">')
    [void]$sb.AppendLine('    <h2>' + (Htm $p.Vardas) + '</h2>')
    [void]$sb.AppendLine('    <p>' + (Htm $p.Tekstas) + '</p>')
    [void]$sb.AppendLine('    <span class="sekcija__kiekis">' + $p.Kadrai.Count + ' photographs</span>')
    [void]$sb.AppendLine('    <div class="lankas"></div>')
    [void]$sb.AppendLine('  </div>')
    [void]$sb.Append((Galerija -Kadrai $p.Kadrai -Sizes $SIZES_KITA))
    [void]$sb.AppendLine('</section>')
    IterpkI -Failas $p.Failas -Turinys $sb.ToString()
    Write-Host ("{0,-16} {1,3} nuotraukos" -f $p.Failas, $p.Kadrai.Count)
}

# --- titulinis: atranka + darbu kunu korteles ---
$viso = 0
foreach ($p in $kunai) { $viso += $p.Kadrai.Count }

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<section class="sekcija" id="selected">')
[void]$sb.AppendLine('  <div class="sekcija__juosta sekcija__juosta--sviesi">')
[void]$sb.AppendLine('    <h2>' + (Htm $atranka.Vardas) + '</h2>')
[void]$sb.AppendLine('    <p>' + (Htm $atranka.Tekstas) + '</p>')
[void]$sb.AppendLine('    <span class="sekcija__kiekis">' + $atranka.Kadrai.Count + ' of ' + $viso + ' photographs</span>')
[void]$sb.AppendLine('  </div>')
[void]$sb.Append((Galerija -Kadrai $atranka.Kadrai -Sizes $SIZES_ATRANKA))
[void]$sb.AppendLine('</section>')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('<section class="kunai">')
[void]$sb.AppendLine('  <h2>Bodies of work</h2>')
[void]$sb.AppendLine('  <div class="kunai__eile">')
foreach ($p in $kunai) {
    $n = $nuotraukos[$p.Kadrai[0].Raktas]
    [void]$sb.AppendLine('    <a class="kunas" href="' + $p.Failas + '">')
    [void]$sb.AppendLine('      <img src="' + $n.Thumb + '" srcset="' + $n.ThumbSm + ' 400w, ' + $n.Thumb + ' 700w" sizes="(max-width:620px) 100vw, 33vw" alt="" width="' + $n.W + '" height="' + $n.H + '" loading="lazy" decoding="async">')
    [void]$sb.AppendLine('      <span class="kunas__vardas">' + (Htm $p.Vardas) + '</span>')
    [void]$sb.AppendLine('      <span class="kunas__kiekis">' + $p.Kadrai.Count + ' photographs</span>')
    [void]$sb.AppendLine('    </a>')
}
[void]$sb.AppendLine('  </div>')
[void]$sb.AppendLine('</section>')
IterpkI -Failas $atranka.Failas -Turinys $sb.ToString()
Write-Host ("{0,-16} {1,3} nuotraukos (atranka) + {2} korteles" -f $atranka.Failas, $atranka.Kadrai.Count, $kunai.Count)

Write-Host ""
Write-Host "-------------------------------------------"
Write-Host ("Apdorota:      {0} nauju, {1} praleista" -f $nauji, $praleisti)
Write-Host ("Puslapiuose:   {0} nuotrauku is {1} apdorotu" -f $viso, $nuotraukos.Count)
Write-Host ("Be alt teksto: {0}" -f (@($nuotraukos.Values | Where-Object { $_.Alt -like "TODO*" }).Count))
Write-Host ""
Write-Host "Nepamirsk padidinti VERSIJA faile sw.js, jei keitei css/js/html."
