# Optimize-Images.ps1
# This script resizes large images in the website folders to Web-friendly sizes (Max 2000px long edge, compressed JPEG)
# It requires the System.Drawing assembly

Add-Type -AssemblyName System.Drawing

$maxWidth = 2000
$maxHeight = 2000

$folders = @("images\projects", "images\gallery", "images\main_page\background")
$count = 0

Write-Host "Scanning for images to optimize (This may take a few minutes)..."

foreach ($f in $folders) {
    if (Test-Path $f) {
        $files = Get-ChildItem -Path $f -Recurse -File | Where-Object { $_.Extension -match "\.(jpg|jpeg)$" }
        foreach ($file in $files) {
            if ($file.Length -gt 1MB) { # Only optimize files larger than 1MB
                Write-Host "Optimizing $($file.Name) ($([math]::Round($file.Length / 1MB, 2)) MB) ..."
                
                try {
                    $img = [System.Drawing.Image]::FromFile($file.FullName)
                    
                    $ratioX = $maxWidth / $img.Width
                    $ratioY = $maxHeight / $img.Height
                    $ratio = [math]::Min($ratioX, $ratioY)
                    
                    if ($ratio -lt 1) {
                        $newWidth = [int]($img.Width * $ratio)
                        $newHeight = [int]($img.Height * $ratio)
                        
                        $newImg = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
                        $graph = [System.Drawing.Graphics]::FromImage($newImg)
                        $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                        $graph.DrawImage($img, 0, 0, $newWidth, $newHeight)
                        
                        $img.Dispose()
                        
                        # Save over the old file
                        $newImg.Save($file.FullName, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                        $newImg.Dispose()
                        $graph.Dispose()
                        $count++
                    } else {
                        $img.Dispose()
                    }
                } catch {
                    Write-Host "Error optimizing $($file.Name): $_"
                }
            }
        }
    }
}

if ($count -eq 0) {
    Write-Host "No large images needed optimization! You're good to go."
} else {
    Write-Host "Successfully optimized $count images!"
}
