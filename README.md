# Justin Tang — Photography Portfolio

Source for **[cogroup.studio](https://cogroup.studio)**. Static HTML/CSS/JS, no framework,
deployed by GitHub Pages from `main`.

## Updating the site

**Read `README - START HERE.txt` — it is the manual.** The short version:

1. Change wording in **`content.txt`** (never in the `.html` files — they're generated).
   Add or remove photos in **`images/`**.
2. Run **`UPDATE WEBSITE.bat`**. It rebuilds every page, makes thumbnails, and checks for
   broken links and mobile problems. Fix anything it reports as a PROBLEM.
3. Check it in a browser, including at phone width.
4. Publish:
   ```bash
   git add .
   git commit -m "Added new automotive photos"
   git push
   ```
   Live in about 60 seconds. Hard-refresh with Ctrl+F5 if you don't see it.

To undo a bad publish: `git revert HEAD && git push`.

## Structure

| Path | What it is |
|---|---|
| `content.txt` | **All site wording.** Edit this, not the HTML. Never rename a `[heading]`. |
| `images/` | All photos. `projects/<name>/4x5/`, `gallery/4x5/`, `main_page/background/`. `thumbs/` is auto-generated — don't touch. |
| `styles.css` | All styling. Global colours are the `:root` variables at the top. |
| `script.js` | Lightbox and page transitions. |
| `index.html`, `gallery.html`, `meetme.html`, `projects.html`, `project-*.html` | Generated pages. Must stay in this top folder or Pages won't find them. |
| `_scripts/` | The build machinery. `UPDATE WEBSITE.bat` runs it; you don't need to open it. |
| `CNAME` | The custom domain. Don't delete it — the domain breaks. |

**Adding a whole new project album** takes two steps: create `images/projects/<name>/4x5/`
*and* copy an existing `project-*.html` to `project-<name>.html`. The build warns you if the
folder exists without a page.

## Domain

`cogroup.studio` is already connected and does not need setting up again. It's wired via the
`CNAME` file plus four A records (`185.199.108–111.153`) and a `www` CNAME at the registrar,
with Enforce HTTPS on in the repo's Pages settings.
