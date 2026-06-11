$projects = @("automotive", "aviation", "concerts", "food", "commission", "f1")

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
        $content = $content -replace "(?s)<!-- BANNER SCRIPT -->.*
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
</body>", "
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
</body>"
        $content = $content -replace "
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
</body>", "<!-- BANNER SCRIPT -->`r`n$bannerJS`r`n
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
</body>"
        
        # --- Masonry Gallery ---
        $htmlStr = ""
        $formats = @("4x5", "5x4", "16x9")
        foreach ($fmt in $formats) {
            if (Test-Path "images\projects\$p\$fmt") {
                $imgs = Get-ChildItem -Path "images\projects\$p\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
                foreach ($img in $imgs) {
                    $htmlStr += "            <div class=`"gallery-photo reveal`"><img src=`"images/projects/$p/$fmt/" + $img.Name + "`" alt=`"$p detail`" loading=`"lazy`"></div>`r`n"
                }
            }
        }
        
        $pattern = "(?s)<div class=`"gallery-masonry`">.*?</div>\s*</section>"
        if ($htmlStr -eq "") {
            $htmlStr = "            <!-- No images uploaded here yet -->`r`n"
        }
        $replacement = "<div class=`"gallery-masonry`">`r`n$htmlStr        </div>`r`n    </section>"
        $content = $content -replace $pattern, $replacement
        
        Set-Content -Path $file -Value $content -Encoding UTF8
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
        <h1 class="huge-text reveal">projects</h1>
        <p class="reveal" style="margin-top: 2rem; max-width: 800px;">A collection of editorial pieces, and deep dives into specific visual stories.</p>
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
                <p style="color: rgba(255,255,255,0.7); margin-bottom: 1rem;">Let's work together</p>
                <a href="mailto:justintangapple@gmail.com" class="footer-email">justintangapple@gmail.com</a>
            </div>
        </div>
        <div class="footer-bottom">
            <span>&copy; 2026 Justin Tang</span>
            <span>built with google antigravity</span>
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
Set-Content -Path "projects.html" -Value $projectsContent -Encoding UTF8

# 3. Update Master Gallery Page
$htmlStrGallery = ""
foreach ($p in $projects) {
    $formats = @("4x5", "5x4", "16x9")
    foreach ($fmt in $formats) {
        if (Test-Path "images\projects\$p\$fmt") {
            $imgs = Get-ChildItem -Path "images\projects\$p\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
            foreach ($img in $imgs) {
                $htmlStrGallery += "            <div class=`"gallery-photo reveal`"><img src=`"images/projects/$p/$fmt/" + $img.Name + "`" alt=`"$p`" loading=`"lazy`"></div>`r`n"
            }
        }
    }
}
$formats = @("4x5", "5x4", "16x9")
foreach ($fmt in $formats) {
    if (Test-Path "images\gallery\$fmt") {
        $imgs = Get-ChildItem -Path "images\gallery\$fmt" -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }
        foreach ($img in $imgs) {
            $htmlStrGallery += "            <div class=`"gallery-photo reveal`"><img src=`"images/gallery/$fmt/" + $img.Name + "`" alt=`"gallery`" loading=`"lazy`"></div>`r`n"
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
    Set-Content -Path $fileGallery -Value $newContent -Encoding UTF8
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
        $indexContent = $indexContent -replace "(?s)<img src=`"images/hero/.*?`" alt=`"Justin Photography`" class=`"hero-image`" id=`"hero-img`">", "<img src=`"$heroPath`" alt=`"Justin Photography`" class=`"hero-image`" id=`"hero-img`">"
    }
    
    # Selected Works Dynamic Generation
    $shuffledProjects = $projects | Get-Random -Count 5
    $worksHtml = ""
    $styles = @("large", "medium", "tall", "medium", "large")
    $delays = @("", " style=`"transition-delay: 0.1s`"", " style=`"transition-delay: 0.2s`"", "", " style=`"transition-delay: 0.1s`"")
    
    for ($i=0; $i -lt 5; $i++) {
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
        if ($i -ne 4) { $worksHtml += "`r`n" }
    }
    
    $pattern = "(?s)<div class=`"works-grid`">.*?</div>\s*</section>"
    if ($indexContent -notmatch "<div class=`"works-grid`">") {
        $pattern = "(?s)<div class=`"bento-grid`">.*?</div>\s*</section>"
    }
    $replacement = "<div class=`"bento-grid`">`r`n$worksHtml`r`n        </div>`r`n    </section>"
    
    $indexContent = $indexContent -replace $pattern, $replacement
    Set-Content -Path "index.html" -Value $indexContent -Encoding UTF8
}

Write-Host "Sync Complete! All HTML files updated."







