# ============================================================
#  UPDATE WEBSITE  -  runs everything, in the right order
# ============================================================
#  This is the only script you need to run.
#
#    1. Applies any wording changes from content.txt
#    2. Makes thumbnails for any new photos
#    3. Rebuilds all the photo grids and pages
#
#  Run it by double-clicking "Update Website.bat"
# ============================================================

param([switch]$NoPause)   # -NoPause: skip the "Press Enter" at the end (for automation)

Set-Location (Split-Path $PSScriptRoot -Parent)   # site root is one level up
$ErrorActionPreference = "Stop"

function Step($n, $title) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  STEP $n of 4 - $title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

# --- snapshot before ---------------------------------------------------------
$imgRoots = @("images\projects", "images\gallery")
function Count-Photos {
    $n = 0
    foreach ($r in $imgRoots) {
        if (Test-Path $r) {
            $n += (Get-ChildItem $r -Recurse -File |
                   Where-Object { $_.Extension -match '\.(jpg|jpeg|png|webp)$' -and $_.DirectoryName -notmatch '\\thumbs$' }).Count
        }
    }
    return $n
}
$photosBefore = Count-Photos

Write-Host ""
Write-Host "############################################################"
Write-Host "#  UPDATING YOUR WEBSITE"
Write-Host "############################################################"
Write-Host ""
Write-Host "Photos found: $photosBefore"

$failed = $false

# --- 1. text -----------------------------------------------------------------
Step 1 "Applying your wording from content.txt"
try {
    if (Test-Path "$PSScriptRoot\Update-Text.ps1") {
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\Update-Text.ps1" -AutoRun
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) { Write-Host "  (finished)" }
    } else {
        Write-Host "  Update-Text.ps1 not found - skipping." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  PROBLEM: $_" -ForegroundColor Red
    $failed = $true
}

# --- 2. shrink oversized exports ---------------------------------------------
# Runs BEFORE thumbnails so thumbnails are made from the web-sized photo.
Step 2 "Shrinking any oversized photos"
try {
    if (Test-Path "$PSScriptRoot\Optimize-Images.ps1") {
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\Optimize-Images.ps1"
    } else {
        Write-Host "  Optimize-Images.ps1 not found - skipping." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  PROBLEM: $_" -ForegroundColor Red
    $failed = $true
}

# --- 3. thumbnails -----------------------------------------------------------
Step 3 "Making thumbnails for any new photos"
try {
    if (Test-Path "$PSScriptRoot\Make-Thumbnails.ps1") {
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\Make-Thumbnails.ps1"
    } else {
        Write-Host "  Make-Thumbnails.ps1 not found - skipping." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  PROBLEM: $_" -ForegroundColor Red
    $failed = $true
}

# --- 4. rebuild pages --------------------------------------------------------
Step 4 "Rebuilding the photo grids and pages"
try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\sync-website.ps1"
} catch {
    Write-Host "  PROBLEM: $_" -ForegroundColor Red
    $failed = $true
}

# --- report ------------------------------------------------------------------
Write-Host ""
Write-Host "############################################################"

$sizes = @{}
Get-ChildItem "images" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $sizes[$_.FullName.Replace((Get-Location).Path + "\","").Replace("\","/")] = $_.Length
}
Write-Host ""
Write-Host "  Page weight (what a visitor downloads):"
foreach ($f in (Get-ChildItem -Filter "*.html" | Sort-Object Name)) {
    $c = Get-Content $f.Name -Raw
    $srcs = [regex]::Matches($c, 'src="(images/[^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    $tot = 0; foreach ($s in $srcs) { if ($sizes.ContainsKey($s)) { $tot += $sizes[$s] } }
    $mb = $tot/1MB
    $flag = if ($mb -gt 25) { "  <-- HEAVY" } else { "" }
    Write-Host ("    {0,-28} {1,6} photos {2,8:N1} MB{3}" -f $f.Name, $srcs.Count, $mb, $flag)
}

# ---- sanity checks ----------------------------------------------------------
Write-Host ""
$problems = @()

# broken links - images, page-to-page links, and lightbox targets.
# NOTE: strip HTML comments first. Commented-out template examples never
# render, so their paths are not broken links.
# This used to check only src="images/..." - which meant a dead href (a nav
# or project link) or a dead data-full (the full-size photo the lightbox
# opens) shipped silently. Now every local reference is checked.
$missing = @()
foreach ($f in (Get-ChildItem -Filter "*.html")) {
    $c = Get-Content $f.Name -Raw
    $live = [regex]::Replace($c, '(?s)<!--.*?-->', '')
    foreach ($m in [regex]::Matches($live, '(?:src|href|data-full)\s*=\s*"([^"]+)"')) {
        $u = $m.Groups[1].Value.Trim()
        if ($u -eq "") { continue }
        if ($u -match '^(#|mailto:|tel:|javascript:|data:)') { continue }
        if ($u -match '^(https?:)?//') { continue }
        $rel = [uri]::UnescapeDataString((($u -split '[?#]')[0]).TrimStart('/'))
        if ($rel -eq "") { continue }
        if (-not (Test-Path ($rel.Replace('/','\')))) {
            $missing += "$($f.Name): $u"
        }
    }
}
if ($missing.Count -gt 0) {
    $problems += "$($missing.Count) link(s) point at files that don't exist:"
    $missing | Select-Object -First 8 | ForEach-Object { $problems += "      $_" }
}

# ---- MOBILE CHECKS ----------------------------------------------------------
$navIcons = @{}
foreach ($f in (Get-ChildItem -Filter "*.html")) {
    $c = Get-Content $f.Name -Raw

    if ($c -notmatch 'name="viewport"') { $problems += "$($f.Name) has no viewport tag - it will render desktop-sized on phones" }
    if ($c -notmatch 'styles\.css')     { $problems += "$($f.Name) does not link styles.css" }
    if ($c -notmatch 'class="mobile-nav"') { $problems += "$($f.Name) has no mobile bottom nav" }

    if ($c -match '(?s)<nav class="mobile-nav">(.*?)</nav>') {
        $nav = $matches[1]
        $navIcons[$f.Name] = "{0}/{1}" -f ([regex]::Matches($nav,'mobile-nav-icon')).Count, ([regex]::Matches($nav,'<a href')).Count
    }
}
$shapes = $navIcons.Values | Select-Object -Unique
if ($shapes.Count -gt 1) {
    $problems += "mobile bottom nav is inconsistent between pages (it will visibly change as you navigate)"
}

# thumbnails present for everything in the grids
$noThumb = 0
foreach ($f in (Get-ChildItem -Filter "*.html")) {
    $c = Get-Content $f.Name -Raw
    foreach ($m in [regex]::Matches($c, '<img src="(images/[^"]+)"[^>]*data-full=')) {
        if ($m.Groups[1].Value -notmatch '/thumbs/') { $noThumb++ }
    }
}
if ($noThumb -gt 0) { $problems += "$noThumb grid image(s) are loading full-size - run Make-Thumbnails.ps1" }

if ($problems.Count -eq 0) {
    Write-Host "  Checks passed:" -ForegroundColor Green
    Write-Host "    - all links resolve (photos, page links, lightbox targets)" -ForegroundColor Green
    Write-Host "    - every page has a viewport tag, styles.css and mobile nav" -ForegroundColor Green
    Write-Host "    - mobile nav identical on all pages ($($shapes[0]) icons/links)" -ForegroundColor Green
    Write-Host "    - all grid images use thumbnails" -ForegroundColor Green
} else {
    Write-Host "  PROBLEMS FOUND:" -ForegroundColor Red
    $problems | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
}

Write-Host ""
if ($failed) {
    Write-Host "  FINISHED WITH PROBLEMS - read the messages above." -ForegroundColor Red
} else {
    Write-Host "  DONE." -ForegroundColor Green
}
Write-Host ""
Write-Host "  NEXT:"
Write-Host "    1. Open index.html and gallery.html in your browser and check them"
Write-Host "    2. Then push to GitHub:"
Write-Host "         git add ."
Write-Host "         git commit -m `"Added new photos`""
Write-Host "         git push"
Write-Host ""
Write-Host "############################################################"
Write-Host ""
if (-not $NoPause) { Read-Host "Press Enter to close" }
