# ============================================================
#  OPTIMIZE IMAGES
# ============================================================
#  Makes big Lightroom exports safe for the web.
#
#  Export at whatever size you like. This shrinks anything
#  oversized down to web dimensions BEFORE it is committed,
#  so the site stays fast and the repo stays small.
#
#  What it does to each photo:
#    - if the long edge is over $MAX_EDGE px  -> resizes it
#    - if the file is still over $SOFT_LIMIT  -> re-encodes it
#    - otherwise                              -> leaves it alone
#
#  The limit is deliberately generous. Squeezing an already
#  web-sized photo from 900KB to 800KB is not worth the quality
#  loss of a second JPEG encode - on a photography site the
#  pixels are the product.
#
#  IMPORTANT: it processes each photo ONCE and records it in
#  .optimized.json. Re-encoding a JPEG over and over degrades
#  it a little each time - the manifest is what prevents that.
#  Your Lightroom catalogue is the real master copy.
# ============================================================

param([switch]$Force)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
Add-Type -AssemblyName System.Drawing

$MAX_EDGE   = 2000       # longest side served to a visitor
$QUALITY    = 85         # JPEG quality for anything re-encoded
$SOFT_LIMIT = 2MB        # re-encode files fatter than this

$manifestPath = Join-Path $PSScriptRoot ".optimized.json"
$manifest = @{}
if ((Test-Path $manifestPath) -and -not $Force) {
    try {
        (Get-Content $manifestPath -Raw | ConvertFrom-Json).PSObject.Properties |
            ForEach-Object { $manifest[$_.Name] = $_.Value }
    } catch { $manifest = @{} }
}

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
             Where-Object { $_.MimeType -eq 'image/jpeg' }

function Save-Jpeg($bitmap, $path, $quality) {
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
        [System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)
    $bitmap.Save($path, $jpegCodec, $ep)
    $ep.Dispose()
}

# A photo shot in portrait can carry an EXIF orientation flag instead of being
# physically rotated. Re-encoding drops that flag, so the rotation has to be
# baked in here or the photo would appear sideways on the site.
function Apply-Exif-Orientation($img) {
    try {
        if ($img.PropertyIdList -contains 274) {
            $o = $img.GetPropertyItem(274).Value[0]
            switch ($o) {
                3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
                6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
                8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
            }
        }
    } catch { }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  OPTIMIZE IMAGES   (max $MAX_EDGE px, quality $QUALITY)"
Write-Host "============================================================"
Write-Host ""

$files = Get-ChildItem "images" -Recurse -File |
         Where-Object { $_.Extension -match '\.(jpg|jpeg)$' -and $_.DirectoryName -notmatch '\thumbs$' }

$done = 0; $skipped = 0; $before = 0; $after = 0; $failed = @()

foreach ($file in $files) {
    $key = $file.FullName.Replace((Get-Location).Path + "\", "").Replace("\", "/")
    $stamp = "$($file.Length):$($file.LastWriteTimeUtc.Ticks)"

    # already handled, and untouched since -> leave it completely alone
    if ($manifest.ContainsKey($key) -and $manifest[$key] -eq $stamp) {
        $skipped++; $before += $file.Length; $after += $file.Length; continue
    }

    try {
        $img = [System.Drawing.Image]::FromFile($file.FullName)
        $longEdge = [Math]::Max($img.Width, $img.Height)
        $needsResize  = $longEdge -gt $MAX_EDGE
        $needsReencode = (-not $needsResize) -and ($file.Length -gt $SOFT_LIMIT)

        if (-not $needsResize -and -not $needsReencode) {
            $img.Dispose()
            $manifest[$key] = $stamp
            $skipped++; $before += $file.Length; $after += $file.Length; continue
        }

        Apply-Exif-Orientation $img
        $ratio = if ($needsResize) { $MAX_EDGE / [Math]::Max($img.Width, $img.Height) } else { 1 }
        $w = [int]($img.Width * $ratio)
        $h = [int]($img.Height * $ratio)

        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($img, 0, 0, $w, $h)
        $img.Dispose()

        # write to a temp file first, so a failure can never destroy the photo
        $tmp = "$($file.FullName).tmp"
        Save-Jpeg $bmp $tmp $QUALITY
        $g.Dispose(); $bmp.Dispose()

        $sizeBefore = $file.Length
        $sizeAfter  = (Get-Item $tmp).Length

        if ($sizeAfter -lt $sizeBefore) {
            Move-Item $tmp $file.FullName -Force
            $after += $sizeAfter
            Write-Host ("  {0,-52} {1,7:N0} KB -> {2,6:N0} KB" -f $file.Name, ($sizeBefore/1KB), ($sizeAfter/1KB))
        } else {
            # re-encoding made it bigger - keep the original
            Remove-Item $tmp -Force
            $after += $sizeBefore
        }
        $before += $sizeBefore
        $done++

        $fresh = Get-Item $file.FullName
        $manifest[$key] = "$($fresh.Length):$($fresh.LastWriteTimeUtc.Ticks)"
    }
    catch {
        $failed += "$($file.Name): $_"
        $before += $file.Length; $after += $file.Length
    }
}

# drop manifest entries for photos that no longer exist
$live = @{}
foreach ($f in $files) { $live[$f.FullName.Replace((Get-Location).Path + "\","").Replace("\","/")] = $true }
foreach ($k in @($manifest.Keys)) { if (-not $live.ContainsKey($k)) { $manifest.Remove($k) } }

$manifest | ConvertTo-Json -Depth 2 | Set-Content $manifestPath -Encoding UTF8

Write-Host ""
Write-Host "Optimized  : $done"
Write-Host "Already fine: $skipped"
if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED ($($failed.Count)):" -ForegroundColor Yellow
    $failed | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}
if ($done -gt 0) {
    Write-Host ""
    Write-Host ("Before: {0:N1} MB" -f ($before/1MB))
    Write-Host ("After : {0:N1} MB" -f ($after/1MB))
    Write-Host ("Saved : {0:N1} MB ({1:N0}%)" -f (($before-$after)/1MB), ((1 - $after/$before) * 100))
}
Write-Host ""
