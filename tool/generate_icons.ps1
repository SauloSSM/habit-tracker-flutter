# Gera variantes PNG do símbolo autoral em assets/images/logo.svg.
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$targets = @{
    'assets/images/logo.png' = 512
    'web/favicon.png' = 32
    'web/icons/Icon-192.png' = 192
    'web/icons/Icon-512.png' = 512
    'web/icons/Icon-maskable-192.png' = 192
    'web/icons/Icon-maskable-512.png' = 512
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png' = 48
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png' = 72
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png' = 96
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png' = 144
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' = 192
}
foreach ($target in $targets.GetEnumerator()) {
    $bitmap = [System.Drawing.Bitmap]::new($target.Value, $target.Value)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#214E42'))
    $graphics.ScaleTransform($target.Value / 120.0, $target.Value / 120.0)
    $leaf = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $leaf.AddBezier(31, 76, 25, 47, 41, 28, 66, 29)
    $leaf.AddBezier(66, 29, 67, 49, 56, 65, 39, 66)
    $leaf.CloseFigure()
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#D5E7AA'))
    $graphics.FillPath($brush, $leaf)
    $brush.Dispose()
    $leaf.Dispose()
    $leaf = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $leaf.AddBezier(60, 81, 57, 59, 69, 44, 92, 45)
    $leaf.AddBezier(92, 45, 93, 65, 82, 78, 66, 78)
    $leaf.CloseFigure()
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#F2BF89'))
    $graphics.FillPath($brush, $leaf)
    $pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#FFF9EE'), 5)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawBezier($pen, 40, 87, 41, 69, 48, 55, 57, 43)
    $graphics.DrawBezier($pen, 62, 88, 64, 75, 72, 63, 82, 55)
    $bitmap.Save((Join-Path $projectRoot $target.Key), [System.Drawing.Imaging.ImageFormat]::Png)
    $pen.Dispose()
    $brush.Dispose()
    $leaf.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
Write-Output 'Logotipo e ícones PNG gerados dentro do projeto.'
