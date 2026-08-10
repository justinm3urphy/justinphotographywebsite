# ============================================================
#  MAKE THUMBNAILS
# ============================================================
#  Creates small copies of your photos for the grid layouts.
#  Your ORIGINAL photos are never touched or modified.
#
#  For every photo like:
#      images/projects/automotive/4x5/MSP00712.jpg
#  it creates:
#      images/projects/automotive/4x5/thumbs/MSP00712.jpg
#
#  The grids load the small one. Clicking opens the full original
#  in the lightbox, at full quality.
#
#  Safe to re-run - it skips thumbnails that are already up to date.
# ============================================================

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)   # site root is one level up
Add-Type -AssemblyName System.Drawing

$MAX_EDGE = 600     # longest side of a thumbnail, in pixels
$QUALITY  = 82      # JPEG quality (0-100). 82 is visually clean.

# Folders whose images appear in grids. Hero backgrounds, client logos
# and the profile photo are shown large, so they are deliberately excluded.
$roots = @("images\projects", "images\gallery")

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
             Where-Object { $_.MimeType -eq 'image/jpeg' }

function Save-Jpeg($bitmap, $path, $quality) {
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
        [System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)
    $bitmap.Save($path, $jpegCodec, $ep)
    $ep.Dispose()
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  MAKE THUMBNAILS   (max $MAX_EDGE px, quality $QUALITY)"
Write-Host "============================================================"
Write-Host ""

$made = 0; $skipped = 0; $failed = @()
$origBytes = 0; $thumbBytes = 0

foreach ($root in $roots) {
    if (-not (Test-Path $root)) { continue }

    $files = Get-ChildItem $root -Recurse -File |
             Where-Object { $_.Extension -match '\.(jpg|jpeg)$' -and $_.DirectoryName -notmatch '\\thumbs$' }

    foreach ($file in $files) {
        $thumbDir = Join-Path $file.DirectoryName "thumbs"
        $thumbPath = Join-Path $thumbDir $file.Name

        if (-not (Test-Path $thumbDir)) { New-Item -ItemType Directory -Force $thumbDir | Out-Null }

        # up to date already?
        if (Test-Path $thumbPath) {
            if ((Get-Item $thumbPath).LastWriteTime -ge $file.LastWriteTime) {
                $skipped++
                $origBytes  += $file.Length
                $thumbBytes += (Get-Item $thumbPath).Length
                continue
            }
        }

        try {
            $img = [System.Drawing.Image]::FromFile($file.FullName)
            $ratio = $MAX_EDGE / [Math]::Max($img.Width, $img.Height)
            if ($ratio -gt 1) { $ratio = 1 }      # never upscale
            $w = [int]($img.Width * $ratio)
            $h = [int]($img.Height * $ratio)

            $bmp = New-Object System.Drawing.Bitmap($w, $h)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.DrawImage($img, 0, 0, $w, $h)
            $img.Dispose()          # release the file handle before saving

            Save-Jpeg $bmp $thumbPath $QUALITY
            $g.Dispose(); $bmp.Dispose()

            $made++
            $origBytes  += $file.Length
            $thumbBytes += (Get-Item $thumbPath).Length
            if ($made % 25 -eq 0) { Write-Host "  ...$made done" }
        }
        catch {
            $failed += "$($file.Name): $_"
        }
    }
}

# --- remove thumbnails whose original photo has been deleted -----------------
$orphans = 0
foreach ($root in $roots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Recurse -Directory | Where-Object { $_.Name -eq "thumbs" } | ForEach-Object {
        $parent = Split-Path $_.FullName -Parent
        Get-ChildItem $_.FullName -File | ForEach-Object {
            if (-not (Test-Path (Join-Path $parent $_.Name))) {
                Remove-Item $_.FullName -Force
                $orphans++
            }
        }
    }
}

Write-Host ""
Write-Host "Created  : $made"
Write-Host "Up to date: $skipped"
if ($orphans -gt 0) {
    Write-Host "Removed  : $orphans orphaned thumbnail(s) (their photo was deleted)"
}
if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED ($($failed.Count)):" -ForegroundColor Yellow
    $failed | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}
if ($origBytes -gt 0) {
    Write-Host ""
    Write-Host ("Originals : {0:N1} MB" -f ($origBytes/1MB))
    Write-Host ("Thumbnails: {0:N1} MB" -f ($thumbBytes/1MB))
    Write-Host ("Saving    : {0:N0}% smaller when browsing grids" -f ((1 - $thumbBytes/$origBytes) * 100))
}
Write-Host ""
Write-Host "Now run sync-website.ps1 so the pages point at the thumbnails."
Write-Host ""
