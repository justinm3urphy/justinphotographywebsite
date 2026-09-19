# ============================================================
#  PREVIEW SERVER
# ============================================================
#  Serves this folder at http://localhost:8080 so the site can be
#  checked locally exactly as a browser will see it online.
#
#  Why not just double-click index.html? Opened as a file, browsers
#  refuse to load the self-hosted font and block a few things the
#  site relies on (history entries for the photo viewer, for one).
#  Served over http it behaves like the live site.
#
#  Run it by double-clicking "PREVIEW.bat". Close the window to stop.
# ============================================================

param([int]$Port = 8080, [switch]$NoBrowser)

Set-Location (Split-Path $PSScriptRoot -Parent)   # site root is one level up
$root = (Get-Location).Path

$types = @{
    ".html" = "text/html; charset=utf-8"; ".css" = "text/css; charset=utf-8"; ".js" = "text/javascript; charset=utf-8"
    ".jpg" = "image/jpeg"; ".jpeg" = "image/jpeg"; ".png" = "image/png"; ".webp" = "image/webp"; ".svg" = "image/svg+xml"
    ".woff2" = "font/woff2"; ".xml" = "application/xml"; ".txt" = "text/plain; charset=utf-8"; ".ico" = "image/x-icon"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() } catch {
    Write-Host "Could not open port $Port (is a preview already running?)." -ForegroundColor Yellow
    Read-Host "Press Enter to close" | Out-Null; exit 1
}
Write-Host ""
Write-Host "  Preview running at  http://localhost:$Port/" -ForegroundColor Green
Write-Host "  Close this window to stop."
Write-Host ""
if (-not $NoBrowser) { Start-Process "http://localhost:$Port/" }

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request; $res = $ctx.Response
    try {
        $rel = [uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
        if ($rel -eq "") { $rel = "index.html" }
        $path = Join-Path $root ($rel -replace '/', '\')
        # never serve outside the site folder
        if (-not $path.StartsWith($root) -or -not (Test-Path $path -PathType Leaf)) {
            $res.StatusCode = 404
            $bytes = [Text.Encoding]::UTF8.GetBytes("404 - $rel")
        } else {
            $ext = [IO.Path]::GetExtension($path).ToLower()
            $res.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
            $res.Headers["Cache-Control"] = "no-cache"
            $bytes = [IO.File]::ReadAllBytes($path)
        }
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } catch {
        try { $res.StatusCode = 500 } catch { }
    } finally {
        $res.OutputStream.Close()
    }
}
