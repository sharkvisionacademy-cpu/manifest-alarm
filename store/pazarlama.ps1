# Pazarlama ekran goruntuleri uretir (1284 x 2778, 24bpp RGB).
# Markali gradyan arka plan + Turkce baslik + telefon cercevesi.
# Ham goruntuler: store\screenshots\ham\  ->  cikti: store\screenshots\pazarlama\
# Basliklar:  store\basliklar.txt  (satir basina  KICKER|BASLIK , UTF-8)

Add-Type -AssemblyName System.Drawing

$W, $H = 1284, 2778
$kok    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ham    = Join-Path $kok "screenshots\ham"
$cikis  = Join-Path $kok "screenshots\pazarlama"
$basPath= Join-Path $kok "basliklar.txt"
New-Item -ItemType Directory -Force $cikis | Out-Null

$basliklar = @(Get-Content $basPath -Encoding UTF8 | Where-Object { $_.Trim() -ne "" })

function New-RoundRect([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x,           $y,           $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y,           $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d,   0, 90)
    $p.AddArc($x,           $y + $h - $d, $d, $d,  90, 90)
    $p.CloseFigure()
    return $p
}

function Wrap-Text([System.Drawing.Graphics]$g, [string]$text, [System.Drawing.Font]$font, [single]$maxW) {
    $kelimeler = $text -split ' '
    $satirlar = New-Object System.Collections.Generic.List[string]
    $mevcut = ""
    foreach ($k in $kelimeler) {
        $deneme = if ($mevcut -eq "") { $k } else { "$mevcut $k" }
        $olcu = $g.MeasureString($deneme, $font)
        if ($olcu.Width -gt $maxW -and $mevcut -ne "") {
            $satirlar.Add($mevcut); $mevcut = $k
        } else { $mevcut = $deneme }
    }
    if ($mevcut -ne "") { $satirlar.Add($mevcut) }
    return $satirlar
}

$sira = 1
$hamDosyalar = Get-ChildItem $ham -File -Include *.png, *.jpg, *.jpeg -Recurse | Sort-Object Name
foreach ($d in $hamDosyalar) {
    $satir  = $basliklar[$sira - 1]
    $parcalar = $satir -split '\|', 2
    $kicker = $parcalar[0].Trim().ToUpper()
    $baslik = $parcalar[1].Trim()

    $kaynak = [System.Drawing.Image]::FromFile($d.FullName)
    $out = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint  = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    # --- Gradyan arka plan (mor -> lacivert -> koyu) ---
    $rect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 40, 32, 74),
        [System.Drawing.Color]::FromArgb(255, 8, 13, 28),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $blend = New-Object System.Drawing.Drawing2D.ColorBlend(3)
    $blend.Colors = @(
        [System.Drawing.Color]::FromArgb(255, 43, 33, 80),
        [System.Drawing.Color]::FromArgb(255, 22, 40, 74),
        [System.Drawing.Color]::FromArgb(255, 8, 13, 28))
    $blend.Positions = @(0.0, 0.42, 1.0)
    $brush.InterpolationColors = $blend
    $g.FillRectangle($brush, $rect)

    # --- Ust merkeze yumusak altin parilti ---
    $glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glowPath.AddEllipse((($W/2) - 620), -360, 1240, 900)
    $pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($glowPath)
    $pgb.CenterColor = [System.Drawing.Color]::FromArgb(60, 242, 201, 76)
    $pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 242, 201, 76))
    $g.FillPath($pgb, $glowPath)

    # --- Kicker (altin, ust) ---
    $kickerFont = New-Object System.Drawing.Font("Segoe UI Semibold", 40, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 242, 201, 76))
    $g.DrawString($kicker, $kickerFont, $goldBrush, [single]($W/2), [single]150, $sf)

    # --- Baslik (beyaz, kalin, sarilir) ---
    $margin = 120
    $baslikFont = New-Object System.Drawing.Font("Segoe UI", 92, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $satirlar = Wrap-Text $g $baslik $baslikFont ([single]($W - 2*$margin))
    $lineH = 104
    $y = 232
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    foreach ($s in $satirlar) {
        $g.DrawString($s, $baslikFont, $whiteBrush, [single]($W/2), [single]$y, $sf)
        $y += $lineH
    }

    # --- Telefon goruntusu: alt bolgeye sigdir, yuvarlak kose + cerceve ---
    $phoneTop = $y + 64
    $altMargin = 96
    $availH = $H - $phoneTop - $altMargin
    $maxPhoneW = $W - 2*130
    $oran = $kaynak.Width / $kaynak.Height
    $pw = [single]($availH * $oran)
    $ph = [single]$availH
    if ($pw -gt $maxPhoneW) { $pw = [single]$maxPhoneW; $ph = [single]($pw / $oran) }
    $px = [single](($W - $pw) / 2)
    $py = [single]$phoneTop
    $rad = [single]($pw * 0.085)
    $bezel = 14

    # golge (birkac katman ile yumusatilmis)
    for ($i = 5; $i -ge 1; $i--) {
        $ofs = $i * 5
        $a = [int](26 - $i*3)
        $sPath = New-RoundRect ([single]($px - $ofs)) ([single]($py - $ofs + 22)) ([single]($pw + 2*$ofs)) ([single]($ph + 2*$ofs)) ([single]($rad + $ofs))
        $sBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 0, 0, 0))
        $g.FillPath($sBrush, $sPath)
        $sBrush.Dispose(); $sPath.Dispose()
    }

    # koyu cerceve (bezel)
    $bezPath = New-RoundRect ([single]($px - $bezel)) ([single]($py - $bezel)) ([single]($pw + 2*$bezel)) ([single]($ph + 2*$bezel)) ([single]($rad + $bezel))
    $bezBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 6, 8, 14))
    $g.FillPath($bezBrush, $bezPath)

    # goruntuyu yuvarlak kose ile kirp ve ciz
    $imgPath = New-RoundRect $px $py $pw $ph $rad
    $g.SetClip($imgPath)
    $g.DrawImage($kaynak, (New-Object System.Drawing.RectangleF($px, $py, $pw, $ph)))
    $g.ResetClip()

    # ince altin cerceve cizgisi
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 242, 201, 76), 2)
    $g.DrawPath($pen, $bezPath)

    $ad = "{0:d2}.png" -f $sira
    $out.Save((Join-Path $cikis $ad), [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output ("{0}  ->  pazarlama\{1}   ({2} satir baslik)" -f $d.Name, $ad, $satirlar.Count)

    $g.Dispose(); $out.Dispose(); $kaynak.Dispose()
    $sira++
}
Write-Output ""
Write-Output ("Bitti: {0}" -f $cikis)
