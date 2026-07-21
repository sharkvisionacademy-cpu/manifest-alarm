# Ekran goruntulerini App Store olcusune getirir (1284 x 2778).
#
# Kullanim:  .\hazirla.ps1
# Goruntuleri once  store\screenshots\ham\  klasorune koyun.
# Sonuclar  store\screenshots\hazir\  klasorune yazilir.

Add-Type -AssemblyName System.Drawing

$hedefW, $hedefH = 1284, 2778
$kok = Split-Path -Parent $MyInvocation.MyCommand.Path
$ham = Join-Path $kok "screenshots\ham"
$hazir = Join-Path $kok "screenshots\hazir"

New-Item -ItemType Directory -Force $ham, $hazir | Out-Null

$dosyalar = Get-ChildItem $ham -File -Include *.png, *.jpg, *.jpeg -Recurse |
    Sort-Object Name

if (-not $dosyalar) {
    Write-Output "Once goruntuleri su klasore koyun: $ham"
    exit
}

$sira = 1
foreach ($d in $dosyalar) {
    $kaynak = [System.Drawing.Image]::FromFile($d.FullName)

    # Hedef orana gore ortadan kirp, sonra tam olcuye olcekle
    $hedefOran = $hedefW / $hedefH
    $kaynakOran = $kaynak.Width / $kaynak.Height
    if ($kaynakOran -gt $hedefOran) {
        $kirpW = [int]($kaynak.Height * $hedefOran)
        $kirpH = $kaynak.Height
    } else {
        $kirpW = $kaynak.Width
        $kirpH = [int]($kaynak.Width / $hedefOran)
    }
    $x = [int](($kaynak.Width - $kirpW) / 2)
    $y = [int](($kaynak.Height - $kirpH) / 2)

    # Apple ekran goruntulerinde alfa kanali kabul etmiyor: 24bit RGB sart
    $cikti = New-Object System.Drawing.Bitmap($hedefW, $hedefH, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($cikti)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage(
        $kaynak,
        (New-Object System.Drawing.Rectangle(0, 0, $hedefW, $hedefH)),
        (New-Object System.Drawing.Rectangle($x, $y, $kirpW, $kirpH)),
        [System.Drawing.GraphicsUnit]::Pixel
    )

    $ad = "{0:d2}.png" -f $sira
    $cikti.Save((Join-Path $hazir $ad), [System.Drawing.Imaging.ImageFormat]::Png)

    Write-Output ("{0}  ->  {1}   ({2}x{3} kaynaktan)" -f $d.Name, $ad, $kaynak.Width, $kaynak.Height)

    $g.Dispose(); $cikti.Dispose(); $kaynak.Dispose()
    $sira++
}

Write-Output ""
Write-Output "$($dosyalar.Count) goruntu hazir: $hazir"
