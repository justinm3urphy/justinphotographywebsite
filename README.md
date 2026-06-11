# Justin Tang — Photography Portfolio (cogroup.studio)

This is the source code for your custom photography portfolio. It is built purely with HTML, CSS, and JavaScript for maximum performance and complete creative control.

---

## 🚀 How to Update Your Website

Your website is connected to GitHub. This means your code acts as the "source of truth". To update your live website, you simply edit the files on your computer and push them to GitHub. 

### Step 1: Make your changes locally
1. Open the project folder in your text editor (like VS Code).
2. Edit your HTML files to add new text, or drop new images into the `images/` folders.
3. You can preview your changes locally by just double-clicking any `.html` file, or by using the VS Code "Live Server" extension.

### Step 2: Push changes to GitHub
Once you are happy with how your changes look locally, open your terminal (PowerShell or Command Prompt) inside your project folder and run these three commands:

```bash
# 1. Stage all your new changes
git add .

# 2. Save the changes with a short message describing what you did
git commit -m "Added new photos to automotive project"

# 3. Upload the changes to GitHub
git push
```

### Step 3: Wait 60 Seconds
The moment you run `git push`, GitHub Pages will automatically detect your new code, build the website, and deploy it to `https://cogroup.studio`. Within a minute or two, your live website will be perfectly updated.

---

## 🌐 Connecting Your Domain (One-Time Setup)

If you haven't linked your `cogroup.studio` domain yet, follow these steps:

1. **GitHub Pages Settings**: Go to your repository on GitHub.com -> **Settings** -> **Pages**.
2. Under "Custom domain", type in `cogroup.studio` and click **Save**.
3. **DNS Settings**: Log into your domain provider (where you bought `cogroup.studio`) and find the DNS or Nameserver settings. Add these four **A Records** (Host: `@`):
   - `185.199.108.153`
   - `185.199.109.153`
   - `185.199.110.153`
   - `185.199.111.153`
4. Add a **CNAME Record** (Host: `www`, Target: `your-github-username.github.io.`).
5. Wait 15-30 minutes for the internet to update, then go back to GitHub Pages settings and check **"Enforce HTTPS"**.

---

## 📁 Project Structure

- `index.html` — The main landing page
- `gallery.html` — The masonry photo gallery
- `meetme.html` — About/Contact page
- `projects.html` — The index of all your project albums
- `project-*.html` — Individual project pages (e.g., `project-automotive.html`)
- `styles.css` — All global styling, colors, and layouts
- `script.js` — The logic for the interactive Lightbox gallery and smooth page transitions
- `images/` — All your highly optimized, compressed images sorted by category

---

## 🎨 Quick Styling Guide

To tweak the global colors of the site, open `styles.css` and look at the very top:
```css
:root {
    --bg-primary: #121212;      /* The dark background color */
    --text-primary: #ffffff;    /* The main white text */
    --text-secondary: #a0a0a0;  /* The grey subtitle text */
    --accent: #222222;          /* Used for footer background */
}
```
Any changes made here will instantly apply to the entire website.
