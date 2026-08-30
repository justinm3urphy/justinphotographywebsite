function initPage() {
    // Reveal Animations using Intersection Observer
    const revealElements = document.querySelectorAll('.reveal');
    
    const revealOptions = {
        threshold: 0.1,
        rootMargin: "0px 0px -50px 0px"
    };
    
    if (typeof IntersectionObserver === 'undefined') {
        // No observer support: reveal everything rather than leaving the page blank.
        revealElements.forEach(el => el.classList.add('active'));
        return;
    }

    const revealOnScroll = new IntersectionObserver(function(entries, observer) {
        entries.forEach(entry => {
            if (!entry.isIntersecting) {
                return;
            } else {
                entry.target.classList.add('active');
                observer.unobserve(entry.target);
            }
        });
    }, revealOptions);
    
    revealElements.forEach(el => {
        revealOnScroll.observe(el);
    });

    // Optional: Dynamic Hero Background image rotation
    // Automatically rotates through your images in the hero folder
    const heroImg = document.getElementById('hero-img');
    if (heroImg) {
        // List of all background images
        const heroImages = [
            'images/main_page/background/DSC01365-Edit-Enhanced-SR.jpg',
            'images/main_page/background/DSC01843-Enhanced-NR-Edit.jpg',
            'images/main_page/background/DSC07055.jpg',
            'images/main_page/background/MSP00763-Enhanced-NR.jpg',
            'images/main_page/background/MSP06558-Edit.jpg',
            'images/main_page/background/MSP07330.jpg',
            'images/main_page/background/MSP07812-Enhanced-NR-3.jpg',
            'images/main_page/background/MSP08197.jpg',
            'images/main_page/background/MSP08212.jpg'
        ];
        
        // Select a random image every time the page refreshes
        const randomIndex = Math.floor(Math.random() * heroImages.length);
        heroImg.src = heroImages[randomIndex];
        
        // Smooth transition styling
        heroImg.style.transition = 'opacity 0.5s ease';
    }

    // Parallax effect on scroll for hero image
    // parallax + navbar scroll handlers are registered once in initScrollEffects()

    // --- PAGE TRANSITIONS (soft navigation) ---
    // Full page loads destroy the Spotify iframe, so internal links are
    // navigated client-side: fetch the page, swap #site-content, keep the
    // player alive. Any failure falls back to a normal page load.
    document.body.classList.add('loaded');

    document.querySelectorAll('#site-content a[href]').forEach(link => {
        link.addEventListener('click', (e) => {
            const target = link.getAttribute('href');
            if (!target) return;
            if (target.startsWith('http') || target.startsWith('mailto') ||
                target.startsWith('tel') || target.startsWith('#')) return;
            if (link.getAttribute('target') === '_blank') return;
            if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
            e.preventDefault();
            navigateTo(target, true);
        });
    });

}

function initLightbox() {
    // --- ADVANCED LIGHTBOX FEATURE ---
    // Soft navigation re-runs this, so clear the previous one first -
    // otherwise a lightbox stacks up on the body per page visited.
    document.querySelectorAll('body > .lightbox').forEach(el => el.remove());
    const lightbox = document.createElement('div');
    lightbox.className = 'lightbox';
    
    const lightboxImg = document.createElement('img');
    const lightboxClose = document.createElement('span');
    lightboxClose.className = 'lightbox-close';
    lightboxClose.innerHTML = '&times;';
    
    const lightboxPrev = document.createElement('span');
    lightboxPrev.className = 'lightbox-nav lightbox-prev';
    lightboxPrev.innerHTML = '&#10094;';
    
    const lightboxNext = document.createElement('span');
    lightboxNext.className = 'lightbox-nav lightbox-next';
    lightboxNext.innerHTML = '&#10095;';
    
    lightbox.appendChild(lightboxImg);
    lightbox.appendChild(lightboxPrev);
    lightbox.appendChild(lightboxNext);
    lightbox.appendChild(lightboxClose);
    document.body.appendChild(lightbox);

    const galleryPhotos = document.querySelectorAll('.gallery-photo img, .slice-details img, .slice-main img');
    let currentImages = [];
    let currentIndex = 0;

    galleryPhotos.forEach((photo, index) => {
        // Grids show a small thumbnail (src). The lightbox opens the full-size
        // original from data-full. Falls back to src if no thumbnail exists.
        currentImages.push(photo.dataset.full || photo.src);
        photo.addEventListener('click', (e) => {
            currentIndex = index;
            showImage(currentIndex);
            lightbox.classList.add('active');
            document.body.style.overflow = 'hidden';
        });
    });

    function showImage(index) {
        if (currentImages.length === 0) return;
        if (index < 0) index = currentImages.length - 1;
        if (index >= currentImages.length) index = 0;
        currentIndex = index;
        lightboxImg.src = currentImages[currentIndex];
    }

    lightboxPrev.addEventListener('click', (e) => {
        e.stopPropagation();
        showImage(currentIndex - 1);
    });

    lightboxNext.addEventListener('click', (e) => {
        e.stopPropagation();
        showImage(currentIndex + 1);
    });

    lightbox.addEventListener('click', (e) => {
        if (e.target !== lightboxImg && e.target !== lightboxPrev && e.target !== lightboxNext) {
            lightbox.classList.remove('active');
            document.body.style.overflow = 'auto';
        }
    });

    document.addEventListener('keydown', (e) => {
        if (!lightbox.classList.contains('active')) return;
        if (e.key === 'Escape') {
            lightbox.classList.remove('active');
            document.body.style.overflow = 'auto';
        } else if (e.key === 'ArrowLeft') {
            showImage(currentIndex - 1);
        } else if (e.key === 'ArrowRight') {
            showImage(currentIndex + 1);
        }
    });
}

// ============================================================================
//  PERSISTENT MUSIC PLAYER + SOFT NAVIGATION
//  ---------------------------------------------------------------------------
//  A browser destroys an <iframe> on a full page load, and reloads it if it is
//  moved in the DOM. So the Spotify player is created ONCE, in a fixed dock
//  that is never re-parented, and internal links swap page content instead of
//  reloading the document. That is the only way playback survives navigation.
// ============================================================================

const SPOTIFY_SRC = 'https://open.spotify.com/embed/playlist/37i9dQZF1EIfeeY1Nyg89M?utm_source=generator';

// Wrap the page in #site-content so navigation can replace it without ever
// touching the player dock or the lightbox.
function ensureShell() {
    if (document.getElementById('site-content')) return;
    const shell = document.createElement('div');
    shell.id = 'site-content';
    while (document.body.firstChild) shell.appendChild(document.body.firstChild);
    document.body.appendChild(shell);
}

function ensurePlayer() {
    if (document.getElementById('player-dock')) return;

    const dock = document.createElement('div');
    dock.id = 'player-dock';
    dock.setAttribute('aria-label', 'Music player');

    const toggle = document.createElement('button');
    toggle.className = 'player-toggle';
    toggle.type = 'button';
    toggle.setAttribute('aria-label', 'Hide player');
    toggle.innerHTML = '&times;';

    const frame = document.createElement('iframe');
    frame.src = SPOTIFY_SRC;
    frame.width = '100%';
    frame.height = '80';
    frame.frameBorder = '0';
    frame.allow = 'autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture';
    frame.title = 'Spotify player';

    dock.appendChild(toggle);
    dock.appendChild(frame);
    document.body.appendChild(dock);

    toggle.addEventListener('click', () => {
        // Only collapses the dock. Never removes the iframe - that would stop
        // the music, which is the entire point of this.
        dock.classList.toggle('collapsed');
        toggle.setAttribute('aria-label',
            dock.classList.contains('collapsed') ? 'Show player' : 'Hide player');
    });
}

// Remove the old inline embed on index.html - the dock replaces it, and two
// players loading the same playlist would fight each other.
function removeInlinePlayer() {
    document.querySelectorAll('#site-content .spotify-wrapper').forEach(el => el.remove());
}

let navigating = false;

async function navigateTo(url, push) {
    if (navigating) return;
    navigating = true;
    try {
        const res = await fetch(url, { credentials: 'same-origin' });
        if (!res.ok) throw new Error('HTTP ' + res.status);
        const html = await res.text();
        const doc = new DOMParser().parseFromString(html, 'text/html');
        const incoming = doc.getElementById('site-content') || doc.body;
        if (!incoming) throw new Error('no content in response');

        // Fade the content only - fading <body> would flash the player too.
        const shell = document.getElementById('site-content');
        shell.style.opacity = '0';
        await new Promise(r => setTimeout(r, 250));   // let the fade finish

        shell.innerHTML = incoming.innerHTML;
        shell.style.opacity = '1';
        document.title = doc.title || document.title;
        if (push) history.pushState({ url: url }, '', url);
        window.scrollTo(0, 0);

        removeInlinePlayer();
        // Content is already swapped and the URL is updated. If page init
        // throws now, log it - do NOT fall back to a full load, that would
        // reload the document and stop the music for a cosmetic failure.
        safeInit();
        navigating = false;
    } catch (err) {
        // Anything at all goes wrong -> plain navigation. The music stops, but
        // the site still works. Never leave the visitor on a dead page.
        console.warn('Soft navigation failed, falling back to a full load:', err);
        navigating = false;
        window.location.href = url;
    }
}

window.addEventListener('popstate', () => {
    navigateTo(location.pathname.split('/').pop() || 'index.html', false);
});

// Registered once for the life of the document. Elements are looked up on
// each scroll because soft navigation replaces them.
function initScrollEffects() {
    window.addEventListener('scroll', () => {
        const heroWrapper = document.querySelector('.hero-image-wrapper');
        if (heroWrapper) {
            heroWrapper.style.transform = `translateY(${window.scrollY * 0.15}px)`;
        }
        const navbar = document.querySelector('.navbar');
        if (!navbar) return;
        if (window.scrollY > 50) {
            navbar.style.background = 'rgba(18, 18, 18, 0.9)';
            navbar.style.backdropFilter = 'blur(10px)';
            navbar.style.mixBlendMode = 'normal';
            navbar.style.paddingTop = '1.25rem';
            navbar.style.paddingBottom = '1.25rem';
            navbar.style.boxShadow = '0 10px 30px rgba(0,0,0,0.3)';
        } else {
            navbar.style.background = 'transparent';
            navbar.style.backdropFilter = 'none';
            navbar.style.mixBlendMode = 'normal';
            navbar.style.paddingTop = '2rem';
            navbar.style.paddingBottom = '2rem';
            navbar.style.boxShadow = 'none';
        }
    });
}

// Each initialiser runs in isolation. A failure in one (a page missing an
// element, an unsupported browser API) must not stop the others - that is how
// the lightbox silently disappeared on pages where reveal setup threw.
function safeInit() {
    try { initPage(); } catch (err) { console.warn('initPage failed:', err); }
    try { initLightbox(); } catch (err) { console.warn('initLightbox failed:', err); }
}

document.addEventListener('DOMContentLoaded', () => {
    ensureShell();
    ensurePlayer();
    removeInlinePlayer();
    initScrollEffects();
    safeInit();
});
