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

    // --- Gear stage (meet me) --------------------------------------------------
    // The section is a tall track with a sticky stage inside. Scroll progress
    // through the track picks the active item; CSS does the crossfade. Items
    // the build hid (no photo yet) are skipped. With fewer than two visible
    // items, or reduced motion, the section stays a plain list.
    // Optical formulas, front to back: groups of elements, each element
    // [left bulge, right bulge, thickness, diameter] in viewBox units. A bulge
    // is positive when that surface is convex. Cemented elements share a
    // surface, so an element's left surface is taken from its neighbour.
    // Element and group counts match the real lenses; the shapes are a
    // schematic, not the manufacturer's diagram.
    const GEAR_OPTICS = {
        'sigma-24-70': [ // 19 elements, 15 groups
            [[40, -15, 26, 230]], [[25, 25, 30, 220]], [[-20, 10, 12, 180], [0, 35, 28, 180]],
            [[-30, -30, 10, 150]], [[15, 15, 24, 140], [0, -20, 10, 140]], [[-25, 25, 14, 130]],
            [[20, 20, 22, 120]], [[-15, -15, 8, 110]], [[30, -10, 20, 120], [0, 25, 18, 120]],
            [[-20, 30, 16, 130]], [[25, 25, 24, 140]], [[-30, -30, 8, 130], [0, 20, 18, 130]],
            [[20, -20, 14, 150]], [[35, 35, 26, 160]], [[-15, 25, 16, 170]]
        ],
        'sony-70-200': [ // 23 elements, 18 groups
            [[35, -10, 22, 260]], [[30, 30, 36, 250]], [[-15, 5, 10, 240], [0, 30, 30, 240]],
            [[-25, -25, 10, 190]], [[20, 20, 26, 170], [0, -15, 10, 170]], [[-20, 25, 12, 150]],
            [[25, 25, 24, 140]], [[-15, -15, 8, 130]], [[15, 15, 20, 120], [0, -10, 8, 120]],
            [[-20, -20, 8, 110]], [[25, -5, 18, 120]], [[-10, 30, 16, 130], [0, -20, 10, 130]],
            [[20, 20, 22, 140]], [[-25, -25, 8, 130]], [[15, 15, 18, 140], [0, -10, 8, 140]],
            [[-20, 20, 12, 150]], [[30, 30, 24, 160]], [[-15, -15, 10, 170]]
        ],
        'sony-200-600': [ // 24 elements, 17 groups
            [[40, -10, 26, 320]], [[35, 35, 40, 310]], [[-20, 10, 12, 300], [0, 35, 34, 300]],
            [[-30, -30, 10, 220]], [[20, 20, 24, 190], [0, -15, 10, 190]], [[-20, -20, 8, 160]],
            [[20, 20, 22, 150], [0, -15, 8, 150]], [[-15, 25, 12, 140]], [[25, 25, 22, 130]],
            [[-20, -20, 8, 120], [0, 20, 18, 120]], [[15, -15, 14, 120]], [[-15, 15, 12, 130], [0, 25, 20, 130]],
            [[20, 20, 20, 140]], [[-25, -25, 8, 140]], [[20, 20, 18, 150], [0, -10, 8, 150]],
            [[-15, -15, 10, 160]], [[25, 25, 22, 170], [0, -15, 10, 170]]
        ]
    };

    // Builds the cross-section for one item. Returns the group nodes and the
    // distance each one travels at full spread, or null if no formula exists.
    const buildOptics = (item, groups, container) => {
        const NS = 'http://www.w3.org/2000/svg';
        const W = 1000, H = 420, CY = H / 2, GAP = 12, MARGIN = 20;
        const widths = groups.map(g => g.reduce((s, e) => s + e[2], 0));
        const assembled = widths.reduce((s, w) => s + w, 0) + GAP * (groups.length - 1);
        const spread = (W - 2 * MARGIN - assembled) / Math.max(1, groups.length - 1);
        const x0 = (W - assembled) / 2;

        const svg = document.createElementNS(NS, 'svg');
        svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
        svg.setAttribute('aria-hidden', 'true');
        const axis = document.createElementNS(NS, 'line');
        axis.setAttribute('class', 'gear-optic-axis');
        axis.setAttribute('x1', 0); axis.setAttribute('x2', W);
        axis.setAttribute('y1', CY); axis.setAttribute('y2', CY);
        svg.appendChild(axis);

        const stopAfter = Math.floor(groups.length * 0.55);
        let x = x0;
        const nodes = groups.map((g, gi) => {
            const node = document.createElementNS(NS, 'g');
            let prevRight = null;
            g.forEach(e => {
                const c1 = prevRight === null ? e[0] : -prevRight;
                const c2 = e[1], t = e[2], h = e[3] / 2;
                const d = 'M' + x + ' ' + (CY - h) +
                    ' Q' + (x - c1) + ' ' + CY + ' ' + x + ' ' + (CY + h) +
                    ' L' + (x + t) + ' ' + (CY + h) +
                    ' Q' + (x + t + c2) + ' ' + CY + ' ' + (x + t) + ' ' + (CY - h) + ' Z';
                const p = document.createElementNS(NS, 'path');
                p.setAttribute('class', 'gear-optic-el');
                p.setAttribute('d', d);
                node.appendChild(p);
                x += t;
                prevRight = c2;
            });
            if (gi === stopAfter) {
                // aperture stop: two bars in the gap before this group
                const sx = x - widths[gi] - GAP / 2;
                [[CY - 110, CY - 50], [CY + 50, CY + 110]].forEach(([y1, y2]) => {
                    const l = document.createElementNS(NS, 'line');
                    l.setAttribute('class', 'gear-optic-stop');
                    l.setAttribute('x1', sx); l.setAttribute('x2', sx);
                    l.setAttribute('y1', y1); l.setAttribute('y2', y2);
                    node.appendChild(l);
                });
            }
            x += GAP;
            svg.appendChild(node);
            return node;
        });

        if (!container) return null;
        container.appendChild(svg);
        const spec = item.querySelector('.gear-spec');
        if (spec) {
            const elements = groups.reduce((s, g) => s + g.length, 0);
            spec.textContent = elements + ' elements \u00b7 ' + groups.length + ' groups';
        }
        return { nodes, spread };
    };

    // Slides the groups apart: 0 = assembled, 1 = fully spread.
    const spreadOptics = (o, amount) => {
        const mid = (o.nodes.length - 1) / 2;
        o.nodes.forEach((g, k) => { g.style.transform = 'translateX(' + ((k - mid) * amount * o.spread) + 'px)'; });
    };

    run('gear', () => {
        const section = document.querySelector('.gear');
        if (!section || section.hidden) return;
        const items = Array.from(section.querySelectorAll('.gear-item')).filter(el => !el.hidden);
        const track = section.querySelector('.gear-track');

        // Reduced motion (or nothing to cycle): a plain list, but the
        // cross-section is content, not decoration, so it is still drawn -
        // fully pulled apart under the photo, with nothing moving.
        if (reduceMotion.matches || items.length < 2 || !track) {
            items.forEach(el => {
                const groups = GEAR_OPTICS[el.dataset.gear];
                if (!groups) return;
                const box = document.createElement('div');
                box.className = 'gear-optics';
                el.appendChild(box);
                const o = buildOptics(el, groups, box);
                if (o) spreadOptics(o, 1);
            });
            section.classList.add('is-static');
            return;
        }

        const rail = section.querySelector('.gear-rail');
        const ticks = items.map(() => {
            const t = document.createElement('span');
            if (rail) rail.appendChild(t);
            return t;
        });

        // Items with a formula get a full step (photo, then the breakdown);
        // the body gets a shorter one.
        const optics = items.map(el => GEAR_OPTICS[el.dataset.gear] ? buildOptics(el, GEAR_OPTICS[el.dataset.gear], el.querySelector('.gear-visual')) : null);
        const weights = optics.map(o => o ? 1 : 0.6);
        const total = weights.reduce((s, w) => s + w, 0);
        const starts = weights.map((w, i) => weights.slice(0, i).reduce((s, x) => s + x, 0) / total);

        section.style.setProperty('--gear-steps', total);
        section.classList.add('is-live');

        // 0 = assembled photo, 1 = fully exploded diagram.
        const EXPLODE_FROM = 0.4, EXPLODE_TO = 0.95;
        const easeOut = x => 1 - Math.pow(1 - x, 3);
        const explode = (i, amount) => {
            const o = optics[i];
            if (!o) return;
            const el = items[i];
            el.classList.toggle('is-exploded', amount > 0);
            spreadOptics(o, easeOut(amount));
        };

        let current = -1;
        const set = i => {
            if (i === current) return;
            current = i;
            items.forEach((el, n) => {
                el.classList.toggle('is-active', n === i);
                el.classList.toggle('is-past', n < i);
                // a fast scroll can skip steps: settle the ones passed over
                if (n < i) explode(n, 1);
                if (n > i) explode(n, 0);
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
            let i = 0;
            while (i + 1 < items.length && progress >= starts[i + 1]) i++;
            set(i);
            const local = (progress - starts[i]) / (weights[i] / total);
            explode(i, Math.min(Math.max((local - EXPLODE_FROM) / (EXPLODE_TO - EXPLODE_FROM), 0), 1));
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
