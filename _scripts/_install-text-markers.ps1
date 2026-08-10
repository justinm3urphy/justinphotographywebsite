# One-time setup: wraps every editable piece of text in HTML comment markers
# so Update-Text.ps1 can find and replace it later.
#
# Safe to re-run: skips anything already marked.
# Run once, then you never need this file again.

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)   # site root is one level up

# key, file(s), exact text to wrap
$targets = @(
    # ---------- index.html ----------
    @{ k="home.title";        f=@("index.html"); t='<h1 class="huge-text">justin tang</h1>'; inner='justin tang' },
    @{ k="home.subtitle";     f=@("index.html"); t='<p class="hero-subtitle">multidisciplinary creative photographer capturing stories through automotive, aviation, food, and concerts.</p>'; inner='multidisciplinary creative photographer capturing stories through automotive, aviation, food, and concerts.' },
    @{ k="home.about_heading"; f=@("index.html"); t='<h2 class="section-title">who i am</h2>'; inner='who i am' },
    @{ k="home.about_body";   f=@("index.html"); t="<p>Hi there! I'm Justin, a multidisciplinary creative photographer aiming to bring ideas to life through creative direction, content creation and visuals on digital platforms as well as in-person marketing campaigns.</p>"; inner="Hi there! I'm Justin, a multidisciplinary creative photographer aiming to bring ideas to life through creative direction, content creation and visuals on digital platforms as well as in-person marketing campaigns." },
    @{ k="home.based_in";     f=@("index.html"); t='<span class="info-value">Singapore</span>'; inner='Singapore' },
    @{ k="home.specialties";  f=@("index.html"); t='<span class="info-value">Automotive, Concerts, Aviation, Food</span>'; inner='Automotive, Concerts, Aviation, Food' },
    @{ k="home.available";    f=@("index.html"); t='<span class="info-value">Freelance / Commission Work</span>'; inner='Freelance / Commission Work' },
    @{ k="home.works_heading"; f=@("index.html"); t='<h2 class="section-title reveal">selected works</h2>'; inner='selected works' },

    # ---------- meetme.html ----------
    @{ k="meetme.title";   f=@("meetme.html"); t='<h1 class="huge-text" style="font-size: clamp(3rem, 8vw, 6rem);">justin tang</h1>'; inner='justin tang' },
    @{ k="meetme.tagline"; f=@("meetme.html"); t='<p style="margin-top: 2rem; font-size: 1.5rem; color: var(--text-primary);">A multidisciplinary creative photographer aiming to bring ideas to life.</p>'; inner='A multidisciplinary creative photographer aiming to bring ideas to life.' },
    @{ k="meetme.body";    f=@("meetme.html"); t="<p style=`"margin-top: 1rem;`">I specialize in creative direction, content creation, and visuals on digital platforms. Whether it's using Adobe Creative Suite, snapping photos, editing content, or working with teams to make projects happen, I simply love creating with others to turn visions into reality.</p>"; inner="I specialize in creative direction, content creation, and visuals on digital platforms. Whether it's using Adobe Creative Suite, snapping photos, editing content, or working with teams to make projects happen, I simply love creating with others to turn visions into reality." },
    @{ k="meetme.location"; f=@("meetme.html"); t='<span class="info-value">Singapore</span>'; inner='Singapore' },

    # ---------- gallery.html ----------
    @{ k="gallery.title"; f=@("gallery.html"); t='<h1 class="huge-text reveal" style="color: white;">gallery</h1>'; inner='gallery' },
    @{ k="gallery.intro"; f=@("gallery.html"); t='<p class="reveal" style="margin-top: 2rem; max-width: 800px; color: var(--text-primary);">A curated selection of individual frames and standout moments from my favorite shoots.</p>'; inner='A curated selection of individual frames and standout moments from my favorite shoots.' },

    # ---------- project pages: hero titles ----------
    @{ k="project.automotive.title"; f=@("project-automotive.html"); t='<h1 class="huge-text reveal">automotive</h1>'; inner='automotive' },
    @{ k="project.aviation.title";   f=@("project-aviation.html");   t='<h1 class="huge-text reveal">aviation</h1>';   inner='aviation' },
    @{ k="project.concerts.title";   f=@("project-concerts.html");   t='<h1 class="huge-text reveal">concerts</h1>';   inner='concerts' },
    @{ k="project.food.title";       f=@("project-food.html");       t='<h1 class="huge-text reveal">food</h1>';       inner='food' },
    @{ k="project.f1.title";         f=@("project-f1.html");         t='<h1 class="huge-text reveal">Formula 1</h1>';  inner='Formula 1' },
    @{ k="project.commission.title"; f=@("project-commission.html"); t='<h1 class="huge-text reveal">commission</h1>'; inner='commission' },

    # ---------- project pages: role + description ----------
    @{ k="project.automotive.role"; f=@("project-automotive.html"); t='<p style="font-size: 1.25rem; font-weight: 600; color: var(--text-primary);">Role: Creative Director & Photographer</p>'; inner='Role: Creative Director & Photographer' },
    @{ k="project.automotive.desc"; f=@("project-automotive.html"); t='<p style="margin-top: 1rem;">Capturing the speed, design, and raw emotion of performance vehicles. This series focuses on sleek lines and dynamic lighting.</p>'; inner='Capturing the speed, design, and raw emotion of performance vehicles. This series focuses on sleek lines and dynamic lighting.' },

    @{ k="project.aviation.role"; f=@("project-aviation.html"); t='<p style="font-size: 1.25rem; font-weight: 600; color: var(--text-primary);">Role: Photographer</p>'; inner='Role: Photographer' },
    @{ k="project.aviation.desc"; f=@("project-aviation.html"); t='<p style="margin-top: 1rem;">Documenting the power and precision of aviation engineering. High-speed action meets careful composition.</p>'; inner='Documenting the power and precision of aviation engineering. High-speed action meets careful composition.' },

    @{ k="project.concerts.role"; f=@("project-concerts.html"); t='<p style="font-size: 1.25rem; font-weight: 600; color: var(--text-primary);">Role: Live Photographer</p>'; inner='Role: Live Photographer' },
    @{ k="project.concerts.desc"; f=@("project-concerts.html"); t='<p style="margin-top: 1rem;">Capturing the raw energy, emotion, and atmosphere of live performances. Working closely with artists to immortalize the stage experience.</p>'; inner='Capturing the raw energy, emotion, and atmosphere of live performances. Working closely with artists to immortalize the stage experience.' },

    @{ k="project.food.role"; f=@("project-food.html"); t='<p style="font-size: 1.25rem; font-weight: 600; color: var(--text-primary);">Role: Food & Beverage Photographer</p>'; inner='Role: Food & Beverage Photographer' },
    @{ k="project.food.desc"; f=@("project-food.html"); t='<p style="margin-top: 1rem;">Highlighting textures, colors, and the culinary artistry behind every dish. Careful styling and lighting to make food look as good as it tastes.</p>'; inner='Highlighting textures, colors, and the culinary artistry behind every dish. Careful styling and lighting to make food look as good as it tastes.' },

    @{ k="project.commission.role"; f=@("project-commission.html"); t='<p style="font-size: 1.25rem; font-weight: 600; color: var(--text-primary);">Role: Freelance Photographer</p>'; inner='Role: Freelance Photographer' },
    @{ k="project.commission.desc"; f=@("project-commission.html"); t='<p style="margin-top: 1rem;">Specialized commission works ranging from product launches to lifestyle shoots.</p>'; inner='Specialized commission works ranging from product launches to lifestyle shoots.' }
)

# Footer text — same on every page
$allHtml = Get-ChildItem -Filter "*.html" | Select-Object -ExpandProperty Name
$footer = @(
    @{ k="site.footer_tagline"; t='<p style="color: rgba(255,255,255,0.7); margin-bottom: 1rem;">Let''s work together</p>'; inner="Let's work together" },
    @{ k="site.email";          t='<a href="mailto:justintangapple@gmail.com" class="footer-email">justintangapple@gmail.com</a>'; inner='justintangapple@gmail.com' },
    @{ k="site.copyright";      t='<span>&copy; 2026 Justin Tang</span>'; inner='&copy; 2026 Justin Tang' },
    @{ k="site.built_with";     t='<span>Built with Google Antigravity</span>'; inner='Built with Google Antigravity' }
)
foreach ($fx in $footer) { $targets += @{ k=$fx.k; f=$allHtml; t=$fx.t; inner=$fx.inner } }

$done = 0; $skipped = 0; $missed = @()

foreach ($tg in $targets) {
    foreach ($file in $tg.f) {
        if (-not (Test-Path $file)) { continue }
        $c = Get-Content $file -Raw -Encoding UTF8

        if ($c -like "*<!--T:$($tg.k)-->*") { $skipped++; continue }
        if (-not $c.Contains($tg.t)) {
            if ($tg.f.Count -eq 1) { $missed += "$($tg.k)  ->  $file" }
            continue
        }

        $marked = $tg.t.Replace($tg.inner, "<!--T:$($tg.k)-->$($tg.inner)<!--/T-->")
        $c = $c.Replace($tg.t, $marked)
        Set-Content $file -Value $c -Encoding UTF8 -NoNewline
        $done++
    }
}

Write-Host ""
Write-Host "Markers inserted : $done"
Write-Host "Already present  : $skipped"
if ($missed.Count -gt 0) {
    Write-Host ""
    Write-Host "NOT FOUND (text may have changed since this script was written):" -ForegroundColor Yellow
    $missed | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
} else {
    Write-Host "All expected text was found." -ForegroundColor Green
}
