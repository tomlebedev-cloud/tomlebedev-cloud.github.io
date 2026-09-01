<#
    Paruosia nuotraukas puslapiui.

    IDEDI CIA:      photos\_originalai\<Galerija>\*.jpg   (bet kokio dydzio)
    SKRIPTAS PADARO: photos\full\   - 2560 px, puslapiui
                     photos\thumb\  - 700 px, galerijos tinkleliui
                     photos.js      - sarasas, pagal kuri piesiama galerija

    Paleidimas (is repozitorijos saknies):
        powershell -ExecutionPolicy Bypass -File tools\paruosti-nuotraukas.ps1

    Originalu nekeicia ir nieko netrina. Jau padarytus failus praleidzia,
    todel pakartotinis paleidimas yra greitas.
#>

param(
    [int]$FullDydis  = 2560,
    [int]$ThumbDydis = 700,
    [int]$Kokybe     = 82
)

Add-Type -AssemblyName System.Drawing

$saknis    = Split-Path -Parent $PSScriptRoot
$originalai = Join-Path $saknis "photos\_originalai"
$full      = Join-Path $saknis "photos\full"
$thumb     = Join-Path $saknis "photos\thumb"

if (-not (Test-Path $originalai)) {
    New-Item -ItemType Directory -Path $originalai -Force | Out-Null
}

$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
       Where-Object { $_.MimeType -eq 'image/jpeg' }
$params = New-Object System.Drawing.Imaging.EncoderParameters(1)
$params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, [long]$Kokybe)

function Sumazink {
    param($Img, [string]$Isvestis, [int]$Riba)

    $mastelis = [Math]::Min($Riba / $Img.Width, $Riba / $Img.Height)
    if ($mastelis -gt 1) { $mastelis = 1 }          # nedidinam
    $nw = [int][Math]::Round($Img.Width  * $mastelis)
    $nh = [int][Math]::Round($Img.Height * $mastelis)

    $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
    try {
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.DrawImage($Img, 0, 0, $nw, $nh)
        } finally { $g.Dispose() }
        $bmp.Save($Isvestis, $enc, $params)
    } finally { $bmp.Dispose() }

    return @($nw, $nh)
}

function TaisykOrientacija {
    # Fotoaparatas vertikalius kadrus iraso horizontaliai, o pasukima
    # nurodo tik EXIF zymeje 274. System.Drawing jos nepaiso, todel
    # pasukam patys - kitaip vertikalios nuotraukos gultu ant sono.
    param($Img)
    if ($Img.PropertyIdList -notcontains 274) { return }
    $o = $Img.GetPropertyItem(274).Value[0]
    switch ($o) {
        2 { $Img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
        3 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        4 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
        5 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
        6 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        7 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
        8 { $Img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }
}

function UrlKelias {
    # kiekviena kelio dali uzkoduojam atskirai, kad tarpai ir
    # lietuviskos raides veiktu ir GitHub Pages serveryje
    param([string]$Kelias)
    $dalys = $Kelias.Split([char]92) | ForEach-Object { [Uri]::EscapeDataString($_) }
    return ($dalys -join "/")
}

# Neprivalomos antrastes: kiekvienoje galerijoje gali guleti pavadinimai.txt,
# kurio eilutes atrodo taip:   DSC_1234.jpg = Rytas prie juros
# Jei failo ten nera, antraste nerodoma - failo vardas NIEKADA nenaudojamas.
$antrastes = @{}
Get-ChildItem -Path $originalai -Recurse -File -Filter pavadinimai.txt -ErrorAction SilentlyContinue | ForEach-Object {
    $gal = $_.Directory.FullName.Substring($originalai.Length).TrimStart([char]92)
    Get-Content $_.FullName -Encoding UTF8 | ForEach-Object {
        $eil = $_.Trim()
        if ($eil -and -not $eil.StartsWith("#") -and $eil.Contains("=")) {
            $k = $eil.Substring(0, $eil.IndexOf("=")).Trim()
            $v = $eil.Substring($eil.IndexOf("=") + 1).Trim()
            $antrastes["$gal|$k"] = $v
        }
    }
}

# Atranka: photos_originalaitranka.txt isvardija geriausias nuotraukas.
# Jos papildomai rodomos atskiroje sekcijoje puslapio virsuje.
$atranka = @{}
$atrankaEile = @{}
$atrankaFailas = Join-Path $originalai "atranka.txt"
if (Test-Path -LiteralPath $atrankaFailas) {
    $nr = 0
    Get-Content -LiteralPath $atrankaFailas -Encoding UTF8 | ForEach-Object {
        $e = $_.Trim()
        if ($e -and -not $e.StartsWith("#")) { $atranka[$e] = $true; $atrankaEile[$e] = $nr; $nr++ }
    }
}

$irasai   = New-Object System.Collections.Generic.List[string]
$nauji    = 0
$praleisti = 0

$failai = Get-ChildItem -Path $originalai -Recurse -File |
          Where-Object { $_.Extension -match '^[.](jpg|jpeg)$' -and $_.Directory.Name -notlike "_*" } |
          Sort-Object FullName

if ($failai.Count -eq 0) {
    Write-Host ""
    Write-Host "photos\_originalai\ tuscias." -ForegroundColor Yellow
    Write-Host "Sudek ten nuotraukas, kiekviena galerija - i savo poaplanki, pvz.:"
    Write-Host "    photos\_originalai\Portugalija\DSC_1234.jpg"
    Write-Host ""
}

foreach ($f in $failai) {

    $rel      = $f.FullName.Substring($originalai.Length).TrimStart('\')
    $galerija = Split-Path $rel -Parent
    if ([string]::IsNullOrWhiteSpace($galerija)) { $galerija = "" }

    $relJpg      = [System.IO.Path]::ChangeExtension($rel, ".jpg")
    $fullKelias  = Join-Path $full  $relJpg
    $thumbKelias = Join-Path $thumb $relJpg

    foreach ($d in @((Split-Path $fullKelias -Parent), (Split-Path $thumbKelias -Parent))) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }

    $reikia = $true
    if ((Test-Path $fullKelias) -and (Test-Path $thumbKelias)) {
        if ((Get-Item $fullKelias).LastWriteTime -ge $f.LastWriteTime) { $reikia = $false }
    }

    $w = 0; $h = 0
    try {
        if ($reikia) {
            $img = [System.Drawing.Image]::FromFile($f.FullName)
            TaisykOrientacija -Img $img
            try {
                $d1 = Sumazink -Img $img -Isvestis $fullKelias  -Riba $FullDydis
                $null = Sumazink -Img $img -Isvestis $thumbKelias -Riba $ThumbDydis
                $w = $d1[0]; $h = $d1[1]
            } finally { $img.Dispose() }
            $nauji++
            Write-Host ("  + {0}  -> {1}x{2}" -f $relJpg, $w, $h)
        } else {
            $img = [System.Drawing.Image]::FromFile($fullKelias)
            try { $w = $img.Width; $h = $img.Height } finally { $img.Dispose() }
            $praleisti++
        }
    } catch {
        Write-Host ("  ! nepavyko: {0} - {1}" -f $rel, $_.Exception.Message) -ForegroundColor Red
        continue
    }

    $raktas = "$galerija|$($f.Name)"
    $pavadinimas = ""
    if ($antrastes.ContainsKey($raktas)) { $pavadinimas = $antrastes[$raktas] }

    $j = [ordered]@{
        full        = ("photos/full/"  + (UrlKelias $relJpg))
        thumb       = ("photos/thumb/" + (UrlKelias $relJpg))
        pavadinimas = $pavadinimas
        galerija    = $galerija
        atranka     = [bool]$atranka[$f.Name]
        atrankaNr   = $(if ($atrankaEile.ContainsKey($f.Name)) { $atrankaEile[$f.Name] } else { -1 })
        w           = $w
        h           = $h
    } | ConvertTo-Json -Compress

    $irasai.Add("  $j")
}

$out = Join-Path $saknis "photos.js"
$turinys = "// Sugeneruota automatiskai - ranka neredaguoti.`r`n" +
           "// Perkurti: powershell -ExecutionPolicy Bypass -File tools\paruosti-nuotraukas.ps1`r`n" +
           "window.PHOTOS = [`r`n" + ($irasai -join ",`r`n") + "`r`n];`r`n"
[System.IO.File]::WriteAllText($out, $turinys, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "-------------------------------------------"
Write-Host ("Nuotrauku:  {0}" -f $failai.Count)
Write-Host ("Naujai apdorota: {0}, praleista (jau buvo): {1}" -f $nauji, $praleisti)
Write-Host ("photos.js atnaujintas")
Write-Host "-------------------------------------------"
