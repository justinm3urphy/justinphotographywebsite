document.addEventListener('DOMContentLoaded', () => {
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

    // Each initialiser is guarded so one failure can't take the others down.
    const run = (name, fn) => {
        try { fn(); } catch (err) { console.error('[' + name + ']', err); }
    };

    // Lets iOS Safari apply :active (press feedback) to non-form elements.
    document.addEventListener('touchstart', () => {}, { passive: true });

    // --- Reveal on scroll ----------------------------------------------------
    run('reveal', () => {
        const els = document.querySelectorAll('.reveal');
        if (!('IntersectionObserver' in window)) {
            els.forEach(el => el.classList.add('active'));
            return;
        }
        const io = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (!entry.isIntersecting) return;
                entry.target.classList.add('active');
                observer.unobserve(entry.target);
            });
        }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });
        els.forEach(el => io.observe(el));
    });

    // --- Scroll: navbar state + hero parallax --------------------------------
    // One passive listener, one write per frame. The navbar's scrolled look is
    // a class (styled in styles.css), not six inline styles per scroll event.
    run('scroll', () => {
        const heroWrapper = document.querySelector('.hero-image-wrapper');
        let ticking = false;
        const update = () => {
            ticking = false;
            const y = window.scrollY;
            document.body.classList.toggle('scrolled', y > 50);
            if (heroWrapper && !reduceMotion.matches) {
                heroWrapper.style.transform = 'translateY(' + (y * 0.15) + 'px)';
            }
        };
        window.addEventListener('scroll', () => {
            if (ticking) return;
            ticking = true;
            requestAnimationFrame(update);
        }, { passive: true });
        update();
    });

    // --- Lightbox --------------------------------------------------------------
    run('lightbox', () => {
        const photos = Array.from(document.querySelectorAll('.gallery-photo img, .slice-details img, .slice-main img'));
        if (photos.length === 0) return;

        const lightbox = document.createElement('div');
        lightbox.className = 'lightbox';
        lightbox.setAttribute('role', 'dialog');
        lightbox.setAttribute('aria-modal', 'true');
        lightbox.setAttribute('aria-label', 'Photo viewer');
        lightbox.setAttribute('aria-hidden', 'true');

        const img = document.createElement('img');
        img.alt = '';

        const button = (className, html, label) => {
            const b = document.createElement('button');
            b.type = 'button';
            b.className = className;
            b.innerHTML = html;
            b.setAttribute('aria-label', label);
            return b;
        };
        const prev = button('lightbox-nav lightbox-prev', '&#10094;', 'Previous photo');
        const next = button('lightbox-nav lightbox-next', '&#10095;', 'Next photo');
        const close = button('lightbox-close', '&times;', 'Close');
        lightbox.append(img, prev, next, close);
        document.body.appendChild(lightbox);

        const fullSrc = p => p.dataset.full || p.src;
        let order = [];     // photos in visual order, set when the lightbox opens
        let index = 0;
        let opener = null;  // the tile that opened the lightbox, for focus return

        // The grid is CSS columns, which lay the DOM out top-to-bottom per
        // column, so DOM order is not reading order. Sort by position so "next"
        // means the photo beside this one, not the one underneath it.
        const visualOrder = () => {
            const rects = photos.map(p => {
                const r = p.getBoundingClientRect();
                return { p, top: r.top, left: r.left, height: r.height };
            });
            const tolerance = (Math.min(...rects.map(r => r.height)) / 2) || 40;
            rects.sort((a, b) => Math.abs(a.top - b.top) < tolerance ? a.left - b.left : a.top - b.top);
            return rects.map(r => r.p);
        };

        const preload = i => {
            const p = order[(i + order.length) % order.length];
            if (p) new Image().src = fullSrc(p);
        };

        const show = i => {
            index = (i + order.length) % order.length;
            img.classList.add('is-loading');
            img.src = fullSrc(order[index]);
            preload(index + 1);
            preload(index - 1);
        };
        img.addEventListener('load', () => img.classList.remove('is-loading'));
        img.addEventListener('error', () => img.classList.remove('is-loading'));

        // Everything behind the dialog is inert while it's open.
        const setInert = on => {
            Array.from(document.body.children).forEach(el => {
                if (el !== lightbox) el.inert = on;
            });
        };

        const open = p => {
            order = visualOrder();
            opener = p;
            show(Math.max(0, order.indexOf(p)));
            lightbox.classList.add('active');
            lightbox.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
            setInert(true);
            close.focus({ preventScroll: true });
        };

        const shut = () => {
            lightbox.classList.remove('active');
            lightbox.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
            setInert(false);
            const target = opener && (opener.closest('.gallery-photo') || opener);
            if (target && typeof target.focus === 'function') target.focus({ preventScroll: true });
        };

        // Tiles are keyboard-operable buttons, not just click targets.
        photos.forEach(p => {
            const tile = p.closest('.gallery-photo') || p;
            tile.setAttribute('tabindex', '0');
            tile.setAttribute('role', 'button');
            tile.setAttribute('aria-label', p.alt ? 'View ' + p.alt : 'View photo');
            tile.addEventListener('click', () => open(p));
            tile.addEventListener('keydown', e => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    open(p);
                }
            });
        });

        prev.addEventListener('click', () => show(index - 1));
        next.addEventListener('click', () => show(index + 1));
        close.addEventListener('click', shut);
        lightbox.addEventListener('click', e => { if (e.target === lightbox) shut(); });

        document.addEventListener('keydown', e => {
            if (!lightbox.classList.contains('active')) return;
            if (e.key === 'Escape') { shut(); return; }
            if (e.key === 'ArrowLeft') { e.preventDefault(); show(index - 1); return; }
            if (e.key === 'ArrowRight') { e.preventDefault(); show(index + 1); return; }
            if (e.key === 'Tab') {
                // Keep focus inside the dialog.
                const focusable = [prev, next, close];
                const i = focusable.indexOf(document.activeElement);
                e.preventDefault();
                const n = e.shiftKey
                    ? (i <= 0 ? focusable.length - 1 : i - 1)
                    : (i === -1 || i === focusable.length - 1 ? 0 : i + 1);
                focusable[n].focus();
            }
        });
    });
});
