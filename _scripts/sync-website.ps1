Set-Location (Split-Path $PSScriptRoot -Parent)   # site root is one level up

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
        
        $bannerCSS = @"
        .project-hero {
            height: 70vh;
            background: var(--text-primary);
            background-size: cover;
            background-position: center 75%;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            transition: background-image 0.5s ease;
        }
        .project-hero::after {
            content: '';
            position: absolute;
            inset: 0;
            background: rgba(0,0,0,0.4);
        }
        .project-hero h1 {
            position: relative;
            z-index: 10;
            color: white;
        }
"@

        $jsArrayStr = ""
        foreach ($img in $bannerImgs) {
            $jsArrayStr += "'images/projects/$p/banner/" + $img.Name + "', "
        }
        if ($jsArrayStr.Length -gt 0) { $jsArrayStr = $jsArrayStr.Substring(0, $jsArrayStr.Length - 2) }

        $bannerJS = ""
        if ($bannerImgs.Count -gt 0) {
            $bannerJS = @"
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const banners = [$jsArrayStr];
            if (banners.length > 0) {
                const randomIndex = Math.floor(Math.random() * banners.length);
                const hero = document.querySelector('.project-hero');
                if (hero) {
                    hero.style.backgroundImage = "url('" + banners[randomIndex] + "')";
                }
            }
        });
    </script>
"@
        }

        $content = Get-Content $file -Raw
        
        # Inject CSS
        if ($content -match "(?s)<style>.*?</style>") {
            $content = $content -replace "(?s)<style>.*?</style>", "<style>$bannerCSS</style>"
        }
        
        # Inject JS
        # ---------------------------------------------------------------
        # REWRITTEN. The original tried to match the entire mobile-nav block
        # as a literal string with unescaped double quotes, which was a
        # PowerShell parse error - this whole script could never run.
        # It also hard-coded a mobile-nav layout that no longer matches the
        # HTML. Anchoring on </body> is simpler and cannot drift.
        # ---------------------------------------------------------------
        $content = $content -replace "(?s)\s*<!-- BANNER SCRIPT -->.*?<!-- /BANNER SCRIPT -->", ""
        if ($bannerJS -ne "") {
            $block = "`r`n<!-- BANNER SCRIPT -->`r`n" + $bannerJS + "`r`n<!-- /BANNER SCRIPT -->`r`n"
            $content = $content.Replace("</body>", $block + "</body>")
        }
        
        # --- Masonry Gallery ---
        $htmlStr = ""
        $formats = @("4x5", "5x4", "16x9")
        foreach ($fmt in $formats) {
            if (Test-Path "images\projects\$p\$fmt") {
                $imgs = Get-ChildItem -Path "images\projects\$p\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
                foreach ($img in $imgs) {
                    $full  = "images/projects/$p/$fmt/" + $img.Name
                    $thumb = if (Test-Path "images\projects\$p\$fmt\thumbs\$($img.Name)") { "images/projects/$p/$fmt/thumbs/" + $img.Name } else { $full }
                    $htmlStr += "            <div class=`"gallery-photo reveal`"><img src=`"$thumb`" data-full=`"$full`" alt=`"$p detail`" loading=`"lazy`"></div>`r`n"
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
$projectsJsObject = ""

foreach ($p in $projects) {
    if ($p -eq "f1") {
        $title = "Formula 1"
        $link = "project-f1.html"
    } else {
        $title = $p -replace "_", " "
        $link = "project-${p}.html"
    }
    
    $imgs4x5 = @()
    if (Test-Path "images\projects\$p\4x5") {
        $imgs4x5 = Get-ChildItem -Path "images\projects\$p\4x5" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
    }
    
    $fallbackImg = "images/main_page/background/MSP06558-Edit.jpg"
    $jsArr = ""
    if ($imgs4x5.Count -gt 0) {
        $fallbackImg = "images/projects/$p/4x5/" + $imgs4x5[0].Name
        foreach ($img in $imgs4x5) {
            $jsArr += "'images/projects/$p/4x5/" + $img.Name + "', "
        }
        $jsArr = $jsArr.Substring(0, $jsArr.Length - 2)
    }
    
    $projectsJsObject += "            '$p': [$jsArr],`r`n"
    
    $projectsHtmlStr += @"
            <a href="$link" class="work-item medium reveal" id="thumb-$p">
                <img src="$fallbackImg" alt="$title" loading="lazy">
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
    <title>Projects — Justin Tang</title>
    <link rel="stylesheet" href="styles.css">
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
    <section class="container" style="padding-top: 20vh; padding-bottom: 5vh;">
        <h1 class="huge-text reveal">$projectsTitle</h1>
        <p class="reveal" style="margin-top: 2rem; max-width: 800px;">$projectsIntro</p>
    </section>

    <!-- Projects List -->
    <section class="container" style="padding-top: 0; padding-bottom: 10vh;">
        <div class="works-grid">
$projectsHtmlStr
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
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const projectImages = {
$projectsJsObject
            };
            
            // Rotate images on load
            for (const [projectId, images] of Object.entries(projectImages)) {
                if (images.length > 0) {
                    const thumb = document.getElementById('thumb-' + projectId);
                    if (thumb) {
                        const imgEl = thumb.querySelector('img');
                        if (imgEl) {
                            const randomIndex = Math.floor(Math.random() * images.length);
                            imgEl.src = images[randomIndex];
                        }
                    }
                }
            }
        });
    </script>

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
$htmlStrGallery = ""
foreach ($p in $projects) {
    $formats = @("4x5", "5x4", "16x9")
    foreach ($fmt in $formats) {
        if (Test-Path "images\projects\$p\$fmt") {
            $imgs = Get-ChildItem -Path "images\projects\$p\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
            foreach ($img in $imgs) {
                $full  = "images/projects/$p/$fmt/" + $img.Name
                $thumb = if (Test-Path "images\projects\$p\$fmt\thumbs\$($img.Name)") { "images/projects/$p/$fmt/thumbs/" + $img.Name } else { $full }
                $htmlStrGallery += "            <div class=`"gallery-photo reveal`"><img src=`"$thumb`" data-full=`"$full`" alt=`"$p`" loading=`"lazy`"></div>`r`n"
            }
        }
    }
}
$formats = @("4x5", "5x4", "16x9")
foreach ($fmt in $formats) {
    if (Test-Path "images\gallery\$fmt") {
        $imgs = Get-ChildItem -Path "images\gallery\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
        foreach ($img in $imgs) {
            $full  = "images/gallery/$fmt/" + $img.Name
            $thumb = if (Test-Path "images\gallery\$fmt\thumbs\$($img.Name)") { "images/gallery/$fmt/thumbs/" + $img.Name } else { $full }
            $htmlStrGallery += "            <div class=`"gallery-photo reveal`"><img src=`"$thumb`" data-full=`"$full`" alt=`"gallery`" loading=`"lazy`"></div>`r`n"
        }
    }
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
        $heroPattern = '<img src="[^"]*" alt="[^"]*" class="hero-image" id="hero-img">'
        if ($indexContent -match $heroPattern) {
            $indexContent = $indexContent -replace $heroPattern, "<img src=`"$heroPath`" alt=`"Justin Tang Photography`" class=`"hero-image`" id=`"hero-img`">"
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
        
        $imgs4x5 = @()
        if (Test-Path "images\projects\$p\4x5") {
            $imgs4x5 = Get-ChildItem -Path "images\projects\$p\4x5" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
        }
        
        $fallbackImg = "images/main_page/background/MSP06558-Edit.jpg"
        if ($imgs4x5.Count -gt 0) {
            # Pick random 4x5 image for the selected works grid
            $randomImg = $imgs4x5 | Get-Random
            $fallbackImg = "images/projects/$p/4x5/" + $randomImg.Name
        }
        
        $style = "bento-item"
        $delay = $delays[$i]
        
        $worksHtml += @"
            <a href="$link" class="$style reveal"$delay>
                <img src="$fallbackImg" alt="$title" loading="lazy">
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
    $replacement = "<div class=`"bento-grid`">`r`n$worksHtml`r`n        </div>`r`n    </section>"
    
    $indexContent = $indexContent -replace $pattern, $replacement
    Write-Page "index.html" $indexContent
}

Write-Host "Sync Complete! All HTML files updated."







