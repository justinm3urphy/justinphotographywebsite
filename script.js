document.addEventListener('DOMContentLoaded', () => {
    // Reveal Animations using Intersection Observer
    const revealElements = document.querySelectorAll('.reveal');
    
    const revealOptions = {
        threshold: 0.1,
        rootMargin: "0px 0px -50px 0px"
    };
    
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
    const heroWrapper = document.querySelector('.hero-image-wrapper');
    if (heroWrapper) {
        window.addEventListener('scroll', () => {
            const scrolled = window.scrollY;
            heroWrapper.style.transform = `translateY(${scrolled * 0.15}px)`;
        });
    }

    // Change Navbar color blending on scroll if needed
    const navbar = document.querySelector('.navbar');
    window.addEventListener('scroll', () => {
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

    // --- PAGE TRANSITIONS ---
    document.body.classList.add('loaded');
    
    const links = document.querySelectorAll('a[href]');
    links.forEach(link => {
        link.addEventListener('click', (e) => {
            const target = link.getAttribute('href');
            // Intercept internal links only
            if (target && !target.startsWith('http') && !target.startsWith('mailto') && link.getAttribute('target') !== '_blank') {
                e.preventDefault();
                document.body.classList.remove('loaded');
                setTimeout(() => {
                    window.location.href = target;
                }, 400); // Wait for fade out
            }
        });
    });

    // --- ADVANCED LIGHTBOX FEATURE ---
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
});
