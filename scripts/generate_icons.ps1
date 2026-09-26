Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\madew\.gemini\antigravity-ide\brain\35c84049-0c58-49a7-9a75-4fd4b78ced20\cvnova_app_logo_1790420929114.jpg"
$baseDir = "c:\Users\madew\Desktop\Git Project\Flutter Projects git\cv_nova"

$srcImage = [System.Drawing.Image]::FromFile($srcPath)

function Resize-Image {
    param(
        [System.Drawing.Image]$Image,
        [int]$Width,
        [int]$Height,
        [string]$OutPath
    )
    $destRect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
    $destImage = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $destImage.SetResolution($Image.HorizontalResolution, $Image.VerticalResolution)

    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $wrapMode = [System.Drawing.Imaging.ImageAttributes]::new()
    $wrapMode.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $graphics.DrawImage($Image, $destRect, 0, 0, $Image.Width, $Image.Height, [System.Drawing.GraphicsUnit]::Pixel, $wrapMode)

    $graphics.Dispose()
    $wrapMode.Dispose()
    $destImage.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destImage.Dispose()
}

# For Adaptive Icon Foreground: center the logo with 15% padding so Android masks never clip it
function Create-AdaptiveForeground {
    param(
        [System.Drawing.Image]$Image,
        [int]$Size,
        [string]$OutPath
    )
    $destImage = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0)) # Transparent
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

    # Emblem occupies 76% of canvas to fit safe zone perfectly
    $innerSize = [int]($Size * 0.76)
    $offset = [int](($Size - $innerSize) / 2)
    $destRect = [System.Drawing.Rectangle]::new($offset, $offset, $innerSize, $innerSize)

    $graphics.DrawImage($Image, $destRect, 0, 0, $Image.Width, $Image.Height, [System.Drawing.GraphicsUnit]::Pixel)

    $graphics.Dispose()
    $destImage.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destImage.Dispose()
}

# 1. Save Flutter Asset logo
$assetLogo = Join-Path $baseDir "assets\images\logo.png"
Resize-Image -Image $srcImage -Width 512 -Height 512 -OutPath $assetLogo
Write-Output "Generated $assetLogo"

# 2. Android Mipmap dimensions
$mipmapConfigs = @(
    @{ Name = "mipmap-mdpi"; Size = 48; FgSize = 108 },
    @{ Name = "mipmap-hdpi"; Size = 72; FgSize = 162 },
    @{ Name = "mipmap-xhdpi"; Size = 96; FgSize = 216 },
    @{ Name = "mipmap-xxhdpi"; Size = 144; FgSize = 324 },
    @{ Name = "mipmap-xxxhdpi"; Size = 192; FgSize = 432 }
)

$resDir = Join-Path $baseDir "android\app\src\main\res"

foreach ($cfg in $mipmapConfigs) {
    $dir = Join-Path $resDir $cfg.Name
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    # Standard legacy launcher icon
    $launcherPath = Join-Path $dir "ic_launcher.png"
    Resize-Image -Image $srcImage -Width $cfg.Size -Height $cfg.Size -OutPath $launcherPath
    Write-Output "Generated $launcherPath"

    # Adaptive foreground
    $fgPath = Join-Path $dir "ic_launcher_foreground.png"
    Create-AdaptiveForeground -Image $srcImage -Size $cfg.FgSize -OutPath $fgPath
    Write-Output "Generated $fgPath"
}

$srcImage.Dispose()
Write-Output "All icons successfully generated!"
