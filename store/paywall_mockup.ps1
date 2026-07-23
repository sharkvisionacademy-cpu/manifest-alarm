# Paywall inceleme ekran goruntusu (mockup) uretir — App Store abonelik incelemesi icin.
# Cikti: store/screenshots/paywall.png (1242 x 2688, 24bpp RGB)

Add-Type -AssemblyName System.Drawing
$W, $H = 1242, 2688
$kok = Split-Path -Parent $MyInvocation.MyCommand.Path
$cikis = Join-Path $kok "screenshots"
New-Item -ItemType Directory -Force $cikis | Out-Null

function New-RoundRect([single]$x,[single]$y,[single]$w,[single]$h,[single]$r){
  $p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$r*2
  $p.AddArc($x,$y,$d,$d,180,90);$p.AddArc($x+$w-$d,$y,$d,$d,270,90)
  $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90);$p.AddArc($x,$y+$h-$d,$d,$d,90,90)
  $p.CloseFigure();return $p
}

$bmp=New-Object System.Drawing.Bitmap($W,$H,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Gradyan arka plan (mor -> lacivert -> koyu)
$rect=New-Object System.Drawing.Rectangle(0,0,$W,$H)
$br=New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,[System.Drawing.Color]::Black,[System.Drawing.Color]::Black,[System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$bl=New-Object System.Drawing.Drawing2D.ColorBlend(3)
$bl.Colors=@([System.Drawing.Color]::FromArgb(255,43,33,80),[System.Drawing.Color]::FromArgb(255,22,40,74),[System.Drawing.Color]::FromArgb(255,8,13,28))
$bl.Positions=@(0.0,0.45,1.0);$br.InterpolationColors=$bl
$g.FillRectangle($br,$rect)

$gold=[System.Drawing.Color]::FromArgb(255,242,201,76)
$goldBrush=New-Object System.Drawing.SolidBrush($gold)
$white=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$night=[System.Drawing.Color]::FromArgb(255,10,10,33)
$sfC=New-Object System.Drawing.StringFormat;$sfC.Alignment=[System.Drawing.StringAlignment]::Center

# Baslik
$fEyebrow=New-Object System.Drawing.Font("Segoe UI",34,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString("PREMIUM",$fEyebrow,$goldBrush,[single]($W/2),[single]120,$sfC)
$fTitle=New-Object System.Drawing.Font("Segoe UI",96,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString("Manifest Premium",$fTitle,$white,[single]($W/2),[single]175,$sfC)
$fSub=New-Object System.Drawing.Font("Segoe UI",40,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$subBrush=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200,255,255,255))
$g.DrawString("Reklamsiz deneyim ve ozel olumlama paketleri",$fSub,$subBrush,[single]($W/2),[single]310,$sfC)

# Faydalar kutusu
$bx=110;$by=430;$bw=$W-2*$bx;$bh=430
$cardBrush=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30,255,255,255))
$cardPath=New-RoundRect $bx $by $bw $bh 28
$g.FillPath($cardBrush,$cardPath)
$fBen=New-Object System.Drawing.Font("Segoe UI",42,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$fCheck=New-Object System.Drawing.Font("Segoe UI",44,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$benefits=@("Reklamsiz, kesintisiz deneyim","5 ozel premium olumlama paketi","Yeni tema ve icerikler ilk sende","Uygulamanin gelisimine destek ol")
$yy=$by+40
foreach($b in $benefits){
  # altin daire (madde imi)
  $g.FillEllipse($goldBrush,[single]($bx+44),[single]($yy+18),[single]26,[single]26)
  $g.DrawString($b,$fBen,$white,[single]($bx+110),[single]($yy+4))
  $yy+=95
}

# Plan kartlari
$plans=@(
  @{name="Haftalik";price='$3,99';per="/ hafta";best=$false},
  @{name="Aylik";price='$9,99';per="/ ay";best=$false},
  @{name="Yillik";price='$39,99';per="/ yil";best=$true}
)
$py=930;$ph=185;$gap=28
$fPlan=New-Object System.Drawing.Font("Segoe UI",50,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$fPer=New-Object System.Drawing.Font("Segoe UI",36,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$fPrice=New-Object System.Drawing.Font("Segoe UI",54,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$fBadge=New-Object System.Drawing.Font("Segoe UI",28,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$perBrush=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180,255,255,255))
foreach($pl in $plans){
  $selected=$pl.best
  $cp=New-RoundRect $bx $py $bw $ph 26
  $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30,255,255,255))),$cp)
  if($selected){$pen=New-Object System.Drawing.Pen($gold,4);$g.DrawPath($pen,$cp)}
  # radio
  $rc=New-Object System.Drawing.Drawing2D.GraphicsPath;$rc.AddEllipse($bx+40,$py+$ph/2-24,48,48)
  if($selected){$g.FillPath($goldBrush,$rc)}else{$penG=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120,255,255,255),4);$g.DrawPath($penG,$rc)}
  $g.DrawString($pl.name,$fPlan,$white,[single]($bx+130),[single]($py+40))
  $g.DrawString($pl.per,$fPer,$perBrush,[single]($bx+132),[single]($py+108))
  $sfR=New-Object System.Drawing.StringFormat;$sfR.Alignment=[System.Drawing.StringAlignment]::Far
  $g.DrawString($pl.price,$fPrice,$goldBrush,(New-Object System.Drawing.RectangleF([single]($bx),[single]($py+55),[single]($bw-40),60)),$sfR)
  if($selected){
    $badgeW=250;$badgeX=$bx+$bw-$badgeW-30;$badgeY=$py-22
    $bp=New-RoundRect $badgeX $badgeY $badgeW 44 22
    $g.FillPath($goldBrush,$bp)
    $g.DrawString("EN AVANTAJLI",$fBadge,(New-Object System.Drawing.SolidBrush($night)),[single]($badgeX+$badgeW/2),[single]($badgeY+7),$sfC)
  }
  $py+=$ph+$gap
}

# CTA butonu
$cy=$py+30;$ch=140
$cta=New-RoundRect $bx $cy $bw $ch 32
$g.FillPath($goldBrush,$cta)
$fCta=New-Object System.Drawing.Font("Segoe UI",52,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString("3 gun ucretsiz dene",$fCta,(New-Object System.Drawing.SolidBrush($night)),[single]($W/2),[single]($cy+40),$sfC)

# Alt bilgi
$fNote=New-Object System.Drawing.Font("Segoe UI",30,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$noteBrush=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150,255,255,255))
$g.DrawString("Abonelik otomatik yenilenir. Istediginde iptal edebilirsin.",$fNote,$noteBrush,[single]($W/2),[single]($cy+$ch+40),$sfC)
$g.DrawString("Satin alimlari geri yukle    Kullanim Kosullari    Gizlilik",$fNote,$noteBrush,[single]($W/2),[single]($cy+$ch+95),$sfC)

$out=Join-Path $cikis "paywall.png"
$bmp.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$bmp.Dispose()
Write-Output "Bitti: $out"
