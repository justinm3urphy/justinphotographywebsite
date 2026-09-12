Set-Location (Split-Path $PSScriptRoot -Parent)   # site root is one level up
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------------------------
# Auto-detect projects from the folders inside images\projects.
# (This used to be a hardcoded list, so a new project folder was silently
#  ignored until someone remembered to edit this script.)
# A project is only used if it also has a matching project-<name>.html page.
# ---------------------------------------------------------------------------
$allFolders = @()
if (Test-Path "images\projects") {
    $allFolders = Get-ChildItem "images\projects" -Directory | Select-Object -ExpandProperty Name | Sort-Object
}
$projects = @()
$orphans  = @()
foreach ($folder in $allFolders) {
    if (Test-Path "project-$folder.html") { $projects += $folder } else { $orphans += $folder }
}
if ($projects.Count -eq 0) {
    Write-Host "No projects found. Expected folders in images\projects with matching project-<name>.html pages." -ForegroundColor Yellow
}
if ($orphans.Count -gt 0) {
    Write-Host ""
    Write-Host "NOTE: these image folders have no matching web page, so they were skipped:" -ForegroundColor Yellow
    $orphans | ForEach-Object { Write-Host "        images\projects\$_   (needs project-$_.html)" -ForegroundColor Yellow }
    Write-Host "      Copy an existing project-*.html and rename it to add one." -ForegroundColor Yellow
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Normalise trailing blank lines: Set-Content used to append a newline on
# every run, so each build silently grew every page by one blank line.

# Cache of thumbnail dimensions. Emitting width/height on every grid image lets
# the browser reserve the correct space before the photo loads, which is what
# stops the masonry grid jumping around as you scroll.
$script:DimCache = @{}
function Get-ImageDims($relPath) {
    if ($script:DimCache.ContainsKey($relPath)) { return $script:DimCache[$relPath] }
    $dims = $null
    try {
        # .NET accepts forward slashes on Windows, so no separator swap is needed.
        $full = Join-Path (Get-Location) $relPath
        if (Test-Path $full) {
            $img = [System.Drawing.Image]::FromFile($full)
            $dims = @{ w = $img.Width; h = $img.Height }
            $img.Dispose()
        }
    } catch { $dims = $null }
    $script:DimCache[$relPath] = $dims
    return $dims
}
function Get-DimAttrs($relPath) {
    $d = Get-ImageDims $relPath
    if ($d) { return (" width=`"" + $d.w + "`" height=`"" + $d.h + "`"") }
    return ""
}

# Aspect ratio as a CSS variable. The grid lays photos out in justified rows
# (styles.css .gallery-masonry) and needs each tile's width/height to do it.
function Get-RatioStyle($relPath) {
    $d = Get-ImageDims $relPath
    if ($d -and $d.h -gt 0) { return (" style=`"--r: " + [math]::Round($d.w / $d.h, 3).ToString([cultureinfo]::InvariantCulture) + "`"") }
    return ""
}

# The first grid photo on a page is its Largest Contentful Paint. Marking it
# lazy tells the browser to fetch it *last*, which is what Core Web Vitals
# measures. First photo: high priority. Next three: normal. The rest: lazy.
function Get-LoadAttrs($n) {
    if ($n -eq 0) { return " fetchpriority=`"high`"" }
    if ($n -lt 4) { return "" }
    return " loading=`"lazy`""
}

# Cover photos for a project's tile on the home page and projects.html.
# If images\projects\<name>\cover\ exists and has photos, only those are used -
# that is how to choose which photos are good enough to be a cover. Otherwise
# every photo in 4x5 is eligible.
function Get-CoverPaths($p) {
    $paths = @()
    foreach ($sub in @("cover", "4x5")) {
        if (Test-Path "images\projects\$p\$sub") {
            $files = Get-ChildItem -Path "images\projects\$p\$sub" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
            if ($files.Count -gt 0) {
                $paths = @($files | ForEach-Object { "images/projects/$p/$sub/" + $_.Name })
                break
            }
        }
    }
    return $paths
}

# Tile <img> with a build-time pick as src plus the full list in data-covers.
# The inline script emitted by Get-CoverRotator swaps src on every page load.
# Grid images are loading="lazy", which the preload scanner skips, so the swap
# happens before any fetch - one download per tile, not two.
function Get-CoverImgTag($covers, $alt) {
    $src = "images/main_page/background/MSP06558-Edit.jpg"
    $attr = ""
    if ($covers.Count -gt 0) { $src = $covers | Get-Random }
    if ($covers.Count -gt 1) { $attr = " data-covers=`"" + ($covers -join "|") + "`"" }
    return "<img src=`"$src`"$attr alt=`"$alt`" loading=`"lazy`">"
}
function Get-CoverRotator() {
    return '<script>document.querySelectorAll("[data-covers]").forEach(function(i){var l=i.dataset.covers.split("|");i.src=l[Math.floor(Math.random()*l.length)]})</script>'
}

function Write-Page($Path,$Text) {
    # Trim every trailing newline, then add back exactly one.
    # Set-Content used to append a newline on top of the one already there,
    # so every build silently grew each page by one blank line.
    $Text = $Text.TrimEnd([char]13,[char]10) + [char]13 + [char]10
    Set-Content -Path $Path -Value $Text -Encoding UTF8 -NoNewline
}

# Read the projects.html wording from content.txt (via content.projects.txt).
# This page is fully regenerated below, so its text CANNOT live in the HTML -
# it would be wiped on every sync. Edit it in content.txt instead, then run
# Update-Text.bat, then run this.
# ---------------------------------------------------------------------------
$projectsTitle  = "projects"
$projectsIntro  = "A collection of editorial pieces, and deep dives into specific visual stories."
$footerTagline  = "Let's work together"
$footerEmail    = "justintangapple@gmail.com"
$footerCopy     = "&copy; 2026 Justin Tang"
$footerBuilt    = "Built with Google Antigravity"

if (Test-Path "$PSScriptRoot\content.projects.txt") {
    foreach ($line in (Get-Content "$PSScriptRoot\content.projects.txt" -Encoding UTF8)) {
        if ($line -match '^\s*#') { continue }
        if ($line -match '^\s*projects\.title\s*=\s*(.+)$')       { $projectsTitle = $matches[1].Trim() }
        if ($line -match '^\s*projects\.intro\s*=\s*(.+)$')       { $projectsIntro = $matches[1].Trim() }
        if ($line -match '^\s*site\.footer_tagline\s*=\s*(.+)$')  { $footerTagline = $matches[1].Trim() }
        if ($line -match '^\s*site\.email\s*=\s*(.+)$')           { $footerEmail   = $matches[1].Trim() }
        if ($line -match '^\s*site\.copyright\s*=\s*(.+)$')       { $footerCopy    = $matches[1].Trim() }
        if ($line -match '^\s*site\.built_with\s*=\s*(.+)$')      { $footerBuilt   = $matches[1].Trim() }
    }
    Write-Host "Using projects.html wording from content.projects.txt"
} else {
    Write-Host "content.projects.txt not found - using built-in default wording."
    Write-Host "  (Run Update-Text.bat first if you've edited content.txt)"
}

Write-Host "Syncing website images..."

# 1. Update Project Pages (Banners and Gallery Masonry)
foreach ($p in $projects) {
    $file = "project-${p}.html"
    if ($p -eq "f1") { $file = "project-f1.html" }
    
    if (Test-Path $file) {
        # --- Banners ---
        $bannerImgs = @()
        if (Test-Path "images\projects\$p\banner") {
            $bannerImgs = Get-ChildItem -Path "images\projects\$p\banner" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
        }
        
        # Pick the banner at build time and write it onto the hero tag as an inline
        # style, so the browser discovers it while parsing instead of after
        # DOMContentLoaded. (No project page has a <style> block, so the old
        # "inject CSS" step here never did anything.)
        $heroTag = '<section class="project-hero">'
        if ($bannerImgs.Count -gt 0) {
            $chosen = $bannerImgs | Get-Random
            $heroTag = '<section class="project-hero" style="background-image: url(''images/projects/' + $p + '/banner/' + $chosen.Name + ''')">'
        }

        $content = Get-Content $file -Raw

        # Banner: replace the hero tag whatever style it currently carries.
        $content = $content -replace '<section class="project-hero"[^>]*>', $heroTag

        # Inject JS
        # ---------------------------------------------------------------
        # REWRITTEN. The original tried to match the entire mobile-nav block
        # as a literal string with unescaped double quotes, which was a
        # PowerShell parse error - this whole script could never run.
        # It also hard-coded a mobile-nav layout that no longer matches the
        # HTML. Anchoring on </body> is simpler and cannot drift.
        # ---------------------------------------------------------------
        # The banner used to be set by a script here. It's on the hero tag now;
        # this strips the old block from pages that still carry it.
        $content = $content -replace "(?s)\s*<!-- BANNER SCRIPT -->.*?<!-- /BANNER SCRIPT -->", ""
        # Older pages also carry an unmarked copy of the same script. Strip that too.
        $content = $content -replace "(?s)\s*<script>\s*document\.addEventListener\('DOMContentLoaded', \(\) => \{\s*const banners = \[.*?</script>", ""

        # --- Masonry Gallery ---
        $htmlStr = ""
        $n = 0
        $formats = @("4x5", "5x4", "16x9")
        foreach ($fmt in $formats) {
            if (Test-Path "images\projects\$p\$fmt") {
                $imgs = Get-ChildItem -Path "images\projects\$p\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
                foreach ($img in $imgs) {
                    $full  = "images/projects/$p/$fmt/" + $img.Name
                    $thumb = if (Test-Path "images\projects\$p\$fmt\thumbs\$($img.Name)") { "images/projects/$p/$fmt/thumbs/" + $img.Name } else { $full }
                    $htmlStr += "            <div class=`"gallery-photo reveal`"$(Get-RatioStyle $thumb)><img src=`"$thumb`" data-full=`"$full`" alt=`"$p detail`"$(Get-LoadAttrs $n) decoding=`"async`"$(Get-DimAttrs $thumb)></div>`r`n"
                    $n++
                }
            }
        }
        
        $pattern = "(?s)<div class=`"gallery-masonry`">.*?</div>\s*</section>"
        if ($htmlStr -eq "") {
            $htmlStr = "            <!-- No images uploaded here yet -->`r`n"
        }
        $replacement = "<div class=`"gallery-masonry`">`r`n$htmlStr        </div>`r`n    </section>"
        $content = $content -replace $pattern, $replacement
        
        Write-Page $file $content
    }
}

# 2. Update projects.html Thumbnails
$projectsHtmlStr = ""

foreach ($p in $projects) {
    if ($p -eq "f1") {
        $title = "Formula 1"
        $link = "project-f1.html"
    } else {
        $title = $p -replace "_", " "
        $link = "project-${p}.html"
    }
    
    $coverImg = Get-CoverImgTag (Get-CoverPaths $p) $title

    $projectsHtmlStr += @"
            <a href="$link" class="work-item medium reveal" id="thumb-$p">
                $coverImg
                <div class="work-caption">
                    <h3>$title</h3>
                    <span>view &rarr;</span>
                </div>
            </a>

"@
}

$projectsContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Longer bodies of work, grouped by what they were for. Automotive, aviation, concerts, food and commissions.">
    <title>Projects — Justin Tang</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap">
    <link rel="stylesheet" href="styles.css">
    <meta property="og:title" content="Projects — Justin Tang">
    <meta property="og:description" content="Longer bodies of work, grouped by what they were for. Automotive, aviation, concerts, food and commissions.">
    <meta property="og:image" content="https://cogroup.studio/images/main_page/background/MSP08212.jpg">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://cogroup.studio/projects.html">
    <meta name="twitter:card" content="summary_large_image">
    <style>
        .works-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 2rem;
        }
        @media (max-width: 900px) {
            .works-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
        @media (max-width: 600px) {
            .works-grid {
                grid-template-columns: 1fr;
            }
        }
        .work-item.medium {
            grid-column: span 1 !important;
            aspect-ratio: 4/5 !important;
        }
    </style>
</head>
<body style="background-color: var(--bg-primary);">
    <!-- Navigation -->
    <nav class="navbar">
        <div class="logo">
            <a href="index.html">justin tang</a>
        </div>
        <ul class="nav-menu">
            <li><a href="projects.html" class="nav-link" style="opacity: 0.6;">projects</a></li>
            <li><a href="gallery.html" class="nav-link">gallery</a></li>
            <li><a href="meetme.html" class="nav-link">meet me</a></li>
        </ul>
    </nav>

    <!-- Projects Header -->
    <section class="container page-header">
        <h1 class="huge-text reveal">$projectsTitle</h1>
        <p class="reveal">$projectsIntro</p>
    </section>

    <!-- Projects List -->
    <section class="container" style="padding-top: 0; padding-bottom: 10vh;">
        <div class="works-grid">
$projectsHtmlStr
            $(Get-CoverRotator)
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="footer-content">
            <div>
                <p style="color: rgba(255,255,255,0.7); margin-bottom: 1rem;"><!--T:site.footer_tagline-->$footerTagline<!--/T--></p>
                <a href="mailto:$footerEmail" class="footer-email"><!--T:site.email-->$footerEmail<!--/T--></a>
            </div>
            <div class="footer-socials" style="display: flex; flex-direction: column; gap: 0.5rem; text-align: right;">
                <a href="https://www.instagram.com/just.in02/" target="_blank" rel="noopener" style="color: rgba(255,255,255,0.7); font-size: 0.875rem;">Main Instagram &#8599;</a>
                <a href="https://www.instagram.com/airbornearchives/" target="_blank" rel="noopener" style="color: rgba(255,255,255,0.7); font-size: 0.875rem;">Aviation Instagram &#8599;</a>
                <a href="https://www.linkedin.com/in/justin-tang-kai-yuan/" target="_blank" rel="noopener" style="color: rgba(255,255,255,0.7); font-size: 0.875rem;">LinkedIn &#8599;</a>
            </div>
        </div>
        <div class="footer-bottom">
            <span><!--T:site.copyright-->$footerCopy<!--/T--></span>
            <span><!--T:site.built_with-->$footerBuilt<!--/T--></span>
        </div>
    </footer>

    <script src="script.js"></script>

    <!-- Mobile Navigation -->
    <nav class="mobile-nav">
        <a href="index.html">
            <span class="mobile-nav-icon">⌂</span>
            home
        </a>
        <a href="projects.html">
            <span class="mobile-nav-icon">▦</span>
            projects
        </a>
        <a href="gallery.html">
            <span class="mobile-nav-icon">◱</span>
            gallery
        </a>
        <a href="meetme.html">
            <span class="mobile-nav-icon">☺</span>
            meet me
        </a>
    </nav>
</body>
</html>
"@
Write-Page "projects.html" $projectsContent

# 3. Update Master Gallery Page
# The gallery is images\gallery only - hand-picked single frames. It used to
# also pour every project photo in, which made it a 210-photo duplicate of the
# albums. Formats are merged and sorted by filename, so a numeric prefix
# (01-, 02-, ...) sets the order.
$htmlStrGallery = ""
$n = 0
$galleryFiles = @()
foreach ($fmt in @("4x5", "5x4", "16x9")) {
    if (Test-Path "images\gallery\$fmt") {
        $galleryFiles += Get-ChildItem -Path "images\gallery\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
    }
}
foreach ($img in ($galleryFiles | Sort-Object Name)) {
    $fmt   = $img.Directory.Name
    $full  = "images/gallery/$fmt/" + $img.Name
    $thumb = if (Test-Path "images\gallery\$fmt\thumbs\$($img.Name)") { "images/gallery/$fmt/thumbs/" + $img.Name } else { $full }
    $htmlStrGallery += "            <div class=`"gallery-photo reveal`"$(Get-RatioStyle $thumb)><img src=`"$thumb`" data-full=`"$full`" alt=`"gallery`"$(Get-LoadAttrs $n) decoding=`"async`"$(Get-DimAttrs $thumb)></div>`r`n"
    $n++
}

$fileGallery = "gallery.html"
if (Test-Path $fileGallery) {
    $content = Get-Content $fileGallery -Raw
    $pattern = "(?s)<div class=`"gallery-masonry`">.*?</div>\s*</section>"
    if ($htmlStrGallery -eq "") {
        $htmlStrGallery = "            <!-- No images uploaded here yet -->`r`n"
    }
    $replacement = "<div class=`"gallery-masonry`">`r`n$htmlStrGallery        </div>`r`n    </section>"
    $newContent = $content -replace $pattern, $replacement
    Write-Page $fileGallery $newContent
}

# 4. UPDATE INDEX.HTML HERO AND SELECTED WORKS
if (Test-Path "index.html") {
    $indexContent = Get-Content "index.html" -Raw
    
    # Hero image rotation
    $heroImgs = @()
    if (Test-Path "images\main_page\background") {
        $heroImgs = Get-ChildItem -Path "images\main_page\background" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
    }
    if ($heroImgs.Count -gt 0) {
        $randomHero = $heroImgs | Get-Random
        $heroPath = "images/main_page/background/" + $randomHero.Name
        # Match ANY current src/alt - the old pattern hard-coded "images/hero/" and
        # alt="Justin Photography", neither of which the file actually contains, so
        # the hero never rotated. Anchored on id="hero-img", which is unique.
        $heroPattern = '<img src="[^"]*" alt="[^"]*" class="hero-image" id="hero-img"[^>]*>'
        if ($indexContent -match $heroPattern) {
            $indexContent = $indexContent -replace $heroPattern, "<img src=`"$heroPath`" alt=`"Justin Tang Photography`" class=`"hero-image`" id=`"hero-img`" fetchpriority=`"high`" decoding=`"async`">"
            Write-Host "Hero image set to: $($randomHero.Name)"
        } else {
            Write-Host "WARNING: could not find the hero image tag in index.html - hero not rotated." -ForegroundColor Yellow
        }
    }
    
    # Selected Works Dynamic Generation
    # Never ask for more projects than exist - Get-Random -Count 5 with fewer
    # than 5 projects returned a short list, and the loop below then emitted
    # <a href="project-.html"> dead links (or crashed on .Substring).
    $slots = [Math]::Min(5, $projects.Count)
    $shuffledProjects = @($projects | Get-Random -Count $slots)
    $worksHtml = ""
    $delays = @("", " style=`"transition-delay: 0.1s`"", " style=`"transition-delay: 0.2s`"", "", " style=`"transition-delay: 0.1s`"")
    
    for ($i=0; $i -lt $slots; $i++) {
        $p = $shuffledProjects[$i]
        
        if ($p -eq "f1") {
            $title = "Formula 1"
            $link = "project-f1.html"
        } else {
            $title = $p -replace "_", " "
            # Capitalize first letter properly
            $title = $title.Substring(0,1).ToUpper() + $title.Substring(1)
            $link = "project-${p}.html"
        }
        
        $coverImg = Get-CoverImgTag (Get-CoverPaths $p) $title
        $style = "bento-item"
        $delay = $delays[$i]

        $worksHtml += @"
            <a href="$link" class="$style reveal"$delay>
                $coverImg
                <div class="work-caption">
                    <h3>$title</h3>
                    <span>View Project &rarr;</span>
                </div>
            </a>
"@
        if ($i -ne ($slots-1)) { $worksHtml += "`r`n" }
    }
    
    $pattern = "(?s)<div class=`"works-grid`">.*?</div>\s*</section>"
    if ($indexContent -notmatch "<div class=`"works-grid`">") {
        $pattern = "(?s)<div class=`"bento-grid`">.*?</div>\s*</section>"
    }
    $replacement = "<div class=`"bento-grid`">`r`n$worksHtml`r`n            $(Get-CoverRotator)`r`n        </div>`r`n    </section>"
    
    $indexContent = $indexContent -replace $pattern, $replacement
    Write-Page "index.html" $indexContent
}

Write-Host "Sync Complete! All HTML files updated."







