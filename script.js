document.addEventListener('DOMContentLoaded', () => {
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

    // Each initialiser is guarded so one failure can't take the others down.
    const run = (name, fn) => {
        try { fn(); } catch (err) { console.error('[' + name + ']', err); }
    };

    // Lets iOS Safari apply :active (press feedback) to non-form elements.
    document.addEventListener('touchstart', () => {}, { passive: true });

    // --- Current page in the navs ----------------------------------------------
    run('nav', () => {
        const here = location.pathname.split('/').pop() || 'index.html';
        // Album pages belong to "projects".
        const section = here.startsWith('project-') ? 'projects.html' : here;
        document.querySelectorAll('.mobile-nav a, .nav-link').forEach(a => {
            if (a.getAttribute('href') === section) {
                a.classList.add('active');
                a.setAttribute('aria-current', 'page');
            }
        });
    });

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
        // Anything already in view at load appears at once: the page just
        // navigated (native crossfade); a float-up on top of that is latency.
        const fold = window.innerHeight;
        els.forEach(el => {
            if (el.getBoundingClientRect().top < fold) {
                el.classList.add('active', 'reveal-instant');
            } else {
                io.observe(el);
            }
        });
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
            // Hysteresis: a jittery trackpad around one threshold flickers the bar.
            const on = document.body.classList.contains('scrolled');
            document.body.classList.toggle('scrolled', y > (on ? 30 : 60));
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

    // --- Gear stage (meet me) --------------------------------------------------
    // The section is a tall track with a sticky stage inside. Scroll progress
    // through the track picks the active item; CSS does the crossfade. Items
    // the build hid (no photo yet) are skipped. With fewer than two visible
    // items the section stays a plain list. Reduced motion keeps the stage
    // and its crossfades but nothing slides (styles.css drops the drift).
    run('gear', () => {
        const section = document.querySelector('.gear');
        if (!section || section.hidden) return;
        const items = Array.from(section.querySelectorAll('.gear-item')).filter(el => !el.hidden);
        const track = section.querySelector('.gear-track');
        if (items.length < 2 || !track) return;

        const rail = section.querySelector('.gear-rail');
        const ticks = items.map(() => {
            const t = document.createElement('span');
            if (rail) rail.appendChild(t);
            return t;
        });

        section.style.setProperty('--gear-steps', items.length);
        section.classList.add('is-live');
        section.classList.toggle('is-reduced', reduceMotion.matches);

        let current = -1;
        const set = i => {
            if (i === current) return;
            current = i;
            items.forEach((el, n) => {
                el.classList.toggle('is-active', n === i);
                el.classList.toggle('is-past', n < i);
            });
            ticks.forEach((t, n) => t.classList.toggle('is-active', n === i));
        };

        let ticking = false;
        const update = () => {
            ticking = false;
            const r = track.getBoundingClientRect();
            const scrollable = r.height - window.innerHeight;
            if (scrollable <= 0) { set(0); return; }
            const progress = Math.min(Math.max(-r.top / scrollable, 0), 0.999);
            set(Math.floor(progress * items.length));
        };
        const onScroll = () => {
            if (ticking) return;
            ticking = true;
            requestAnimationFrame(update);
        };
        window.addEventListener('scroll', onScroll, { passive: true });
        window.addEventListener('resize', onScroll);
        update();
    });

    // --- Lightbox --------------------------------------------------------------
    run('lightbox', () => {
        const photos = Array.from(document.querySelectorAll('.gallery-photo img'));
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
        const order = photos;   // justified rows: DOM order is reading order
        let index = 0;
        let opener = null;      // the tile that opened the lightbox, for focus return

        const preload = i => {
            const p = order[(i + order.length) % order.length];
            if (p) new Image().src = fullSrc(p);
        };

        // Thumb first: the tile's image is on screen and cached, so it appears
        // the instant a photo is chosen, soft (is-loading) until the full-size
        // file has decoded, then swaps in sharp. Before, the previous photo
        // sat dimmed until the new ~450 KB file arrived.
        let pending = null;
        const show = i => {
            index = (i + order.length) % order.length;
            const p = order[index];
            if (pending) { pending.onload = pending.onerror = null; }
            img.src = p.currentSrc || p.src;
            img.alt = p.alt || '';
            img.classList.add('is-loading');
            const full = new Image();
            pending = full;
            full.onload = () => { if (pending === full) { img.src = full.src; img.classList.remove('is-loading'); } };
            full.onerror = () => { if (pending === full) img.classList.remove('is-loading'); };
            full.src = fullSrc(p);
            preload(index + 1);
            preload(index - 1);
        };

        // Everything behind the dialog is inert while it's open.
        const setInert = on => {
            Array.from(document.body.children).forEach(el => {
                if (el !== lightbox) el.inert = on;
            });
        };

        const open = p => {
            opener = p;
            show(Math.max(0, order.indexOf(p)));
            lightbox.classList.add('active');
            lightbox.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
            setInert(true);
            close.focus({ preventScroll: true });
            // A history entry, so the phone's Back button closes the viewer
            // instead of leaving the page.
            try { history.pushState({ lightbox: true }, ''); } catch (e) { /* file:// origins refuse it */ }
        };

        const finishShut = () => {
            lightbox.classList.remove('active');
            lightbox.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
            setInert(false);
            const target = opener && (opener.closest('.gallery-photo') || opener);
            if (target && typeof target.focus === 'function') target.focus({ preventScroll: true });
        };

        // Close via history so the entry pushed on open is consumed either way.
        const shut = () => {
            if (history.state && history.state.lightbox) history.back();
            else finishShut();
        };
        window.addEventListener('popstate', () => {
            if (lightbox.classList.contains('active')) finishShut();
        });

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

        // Directional change for the buttons and swipes: the photo leaves the
        // way it is going and the next one comes in from the other side.
        // Keyboard arrows keep the instant swap (frequent, no animation).
        let stepping = false;
        const stepTo = (delta, dir) => {
            if (stepping) return;
            stepping = true;
            const move = !reduceMotion.matches;
            lightbox.classList.remove('is-dragging');
            img.style.transition = 'transform 200ms var(--ease-out), opacity 200ms ease';
            img.style.transform = move ? 'translateX(' + (dir * window.innerWidth * 0.3) + 'px)' : '';
            img.style.opacity = '0';
            setTimeout(() => {
                show(index + delta);
                img.style.transition = 'none';
                img.style.transform = move ? 'translateX(' + (-dir * 32) + 'px)' : '';
                void img.offsetWidth; // flush, so the next change animates
                img.style.transition = 'transform 250ms var(--ease-out), opacity 250ms ease';
                img.style.transform = '';
                img.style.opacity = '';
                setTimeout(() => { img.style.transition = ''; lightbox.style.backgroundColor = ''; stepping = false; }, 260);
            }, 200);
        };

        prev.addEventListener('click', () => stepTo(-1, 1));
        next.addEventListener('click', () => stepTo(1, -1));
        close.addEventListener('click', shut);

        // --- Touch: swipe sideways for prev/next, pull down to close --------------
        // Pointer Events with capture. Nothing happens until the finger has
        // moved 10 px; then the axis locks. Horizontal tracks 1:1; vertical
        // shrinks the photo and thins the scrim so the page shows through, with
        // a rubber band past 300 px. Release commits on distance or on velocity
        // in the same direction as the drag; otherwise it settles back.
        const swipe = { id: null, x0: 0, y0: 0, axis: null, samples: [] };
        const settle = () => {
            swipe.id = null;
            lightbox.classList.remove('is-dragging');
            img.style.transform = '';
            lightbox.style.backgroundColor = '';
        };
        const velocity = () => {
            const s = swipe.samples;
            if (s.length < 2) return { vx: 0, vy: 0 };
            const a = s[0], b = s[s.length - 1];
            const dt = Math.max(1, b.t - a.t);
            return { vx: (b.x - a.x) / dt, vy: (b.y - a.y) / dt };
        };
        lightbox.addEventListener('pointerdown', e => {
            if (!lightbox.classList.contains('active') || e.pointerType === 'mouse') return;
            if (swipe.id !== null || stepping) return;          // one finger at a time
            if (e.target === prev || e.target === next || e.target === close) return;
            swipe.id = e.pointerId; swipe.x0 = e.clientX; swipe.y0 = e.clientY; swipe.axis = null;
            swipe.samples = [{ x: e.clientX, y: e.clientY, t: e.timeStamp }];
            try { lightbox.setPointerCapture(e.pointerId); } catch (err) { /* synthetic events */ }
        });
        lightbox.addEventListener('pointermove', e => {
            if (e.pointerId !== swipe.id) return;
            const dx = e.clientX - swipe.x0, dy = e.clientY - swipe.y0;
            swipe.samples.push({ x: e.clientX, y: e.clientY, t: e.timeStamp });
            if (swipe.samples.length > 5) swipe.samples.shift();
            if (!swipe.axis) {
                if (Math.abs(dx) < 10 && Math.abs(dy) < 10) return;
                swipe.axis = Math.abs(dx) >= Math.abs(dy) ? 'x' : 'y';
                lightbox.classList.add('is-dragging');
            }
            if (swipe.axis === 'x') {
                img.style.transform = 'translateX(' + dx + 'px)';
            } else {
                let d = dy;
                if (Math.abs(d) > 300) d = Math.sign(d) * (300 + (Math.abs(d) - 300) * 0.3);
                const k = Math.min(Math.abs(d), 300) / 300;
                img.style.transform = 'translateY(' + d + 'px) scale(' + (1 - k * 0.15) + ')';
                lightbox.style.backgroundColor = 'rgba(0,0,0,' + (0.95 - k * 0.6) + ')';
            }
        });
        const release = e => {
            if (e.pointerId !== swipe.id) return;
            const dx = e.clientX - swipe.x0, dy = e.clientY - swipe.y0;
            const axis = swipe.axis, v = velocity();
            if (e.type === 'pointercancel' || !axis) { settle(); return; }
            if (axis === 'x') {
                const far = Math.abs(dx) > window.innerWidth * 0.25;
                const fast = Math.abs(v.vx) > 0.11 && Math.sign(v.vx) === Math.sign(dx);
                swipe.id = null;
                if (far || fast) stepTo(dx < 0 ? 1 : -1, dx < 0 ? -1 : 1);
                else settle(); // .active's 300 ms transform transition carries it back
            } else {
                const far = Math.abs(dy) > 120;
                const fast = Math.abs(v.vy) > 0.11 && Math.sign(v.vy) === Math.sign(dy);
                if (far || fast) { shut(); setTimeout(settle, 200); }
                else settle();
            }
        };
        lightbox.addEventListener('pointerup', release);
        lightbox.addEventListener('pointercancel', release);
        lightbox.addEventListener('lostpointercapture', e => { if (e.pointerId === swipe.id) settle(); });
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
