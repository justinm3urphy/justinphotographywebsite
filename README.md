# Justin's Photography Portfolio Website

## 📁 Project Structure
```
project/
├── index.html          # Main website file
├── styles.css          # All styling and colors
├── script.js           # Interactivity and menu toggle
└── README.md           # This file
```

---

## 🚀 How to View Your Website Locally

### Option 1: Double-click the file (Easiest)
1. Open the project folder: `C:\Users\Justin\Desktop\Justin's Photography Website\project`
2. Double-click `index.html`
3. Your website will open in your default browser
4. That's it! You can now see your website live locally

### Option 2: Use VS Code (Recommended for editing)
1. Open VS Code
2. Open the `project` folder (File → Open Folder)
3. Right-click `index.html` → "Open with Live Server" (if you have Live Server extension)
4. Or just double-click `index.html`

---

## 🎨 How to Customize Colors

### Your Custom Color Scheme (Optimized for Your Photography)

**Background:** Pure White (#FFFFFF)
- ✓ Professional and clean
- ✓ Lets your automotive, airplane, food, and concert photos shine
- ✓ High contrast with text

**Accent Color:** Deep Teal-Blue (#1B6B7A)
- ✓ Modern and professional (perfect for automotive photography)
- ✓ Sky-like and expansive (complements airplane photography)
- ✓ Dynamic and energetic (suits concert photography)
- ✓ Sophisticated and elegant (enhances food photography)

**Text:** Dark Gray (#333333)
- ✓ High contrast and easy to read
- ✓ Professional appearance

### Want to Change Colors Again?

Open `styles.css` and find the **COLOR PALETTE** section at the very top.

Replace these values under `:root {`:
```css
--bg-primary: #FFFFFF;          /* Background */
--accent-color: #1B6B7A;        /* Buttons & highlights */
--text-primary: #333333;        /* Main text */
```

Then save the file and refresh your browser.

---

## 📸 How to Add Your Photos

### Replace Placeholder Images

Currently, the gallery has 12 placeholder images. Replace them with your actual photos:

1. Open `index.html`
2. Find the gallery section (search for `gallery-grid`)
3. Each photo has a line like:
   ```html
   <img src="https://via.placeholder.com/400x300?text=Architecture+1" alt="Architecture Portfolio" class="gallery-image">
   ```

4. Replace the `src="..."` with your image:

**Option A: Use image from your computer**
```html
<img src="photo1.jpg" alt="Description" class="gallery-image">
```
(Then put `photo1.jpg` in the same `project` folder)

**Option B: Use image from internet (URL)**
```html
<img src="https://yourwebsite.com/photo1.jpg" alt="Description" class="gallery-image">
```

5. Update the category tags too:
```html
<span class="gallery-tag">Architecture</span>  <!-- Change this -->
```

---

## 📝 How to Update Text

### Update Your Contact Info
In `index.html`, find the **Contact Section** and update:
1. Email: `justintle0714@gmail.com`
2. Instagram handle: `@yourinstagram`

### Update About Section
Search for "Hi, I'm Justin!" and update your bio text.

### Update Navigation Links
The menu automatically links to sections. You can add new sections by:
1. Adding a `<section id="name">` in HTML
2. Adding a link in the navbar: `<li><a href="#name">Name</a></li>`

---

## 🔧 Customization Tips

### Change Hero Title
Search for: `<h1>Photography that Tells Stories</h1>`
Replace with your own tagline

### Change Hero Subtitle
Search for: `<p>Architecture • Food • Cars • And More</p>`
Customize with your photo genres

### Update Specialties List
Find the section with:
```html
<li>Architecture Photography</li>
```
Add/remove/edit as needed

---

## ✨ Features Included

✅ Responsive design (works on mobile, tablet, desktop)
✅ Smooth scrolling navigation
✅ Mobile hamburger menu
✅ Hover effects on gallery images
✅ Professional styling
✅ Contact section (links to Instagram & Email)
✅ About section with detailed bio
✅ Footer with quick links
✅ Customizable color palette

---

## 📱 Mobile & Desktop Compatibility

The website automatically adapts to:
- ✅ Desktop (1200px and above)
- ✅ Tablet (768px - 1200px)
- ✅ Mobile (under 480px)

Test on your phone by:
1. Open `index.html` on your phone
2. Or use Chrome DevTools: F12 → Click mobile icon

---

## 🌐 Next Steps: Deploy to Internet

When you're ready to go live:

**Option 1: Vercel (FREE - Recommended)**
1. Create GitHub account (github.com)
2. Create Vercel account (vercel.com)
3. Upload your `project` folder to GitHub
4. Connect Vercel to GitHub
5. Deploy with one click
6. Connect your domain (future step)

**Option 2: Traditional Hosting**
1. Buy domain + hosting (Namecheap, Bluehost, etc.)
2. Use FTP to upload files
3. Connect domain

**Option 3: GitHub Pages (FREE)**
1. Create GitHub account
2. Upload files to a repository named `yourname.github.io`
3. Instant deployment!

---

## 🆘 Troubleshooting

**Images not showing?**
- Make sure image files are in the same folder as `index.html`
- Or use full image URLs (starting with `https://`)

**Colors not changing?**
- Make sure you edited the right lines in `styles.css`
- Clear browser cache (Ctrl+Shift+Delete)

**Mobile menu not working?**
- Check browser console (F12) for errors
- Make sure `script.js` is in the same folder

---

## 📞 Contact & Support

Need help? Check:
1. The comments in the CSS and HTML files
2. VS Code live preview
3. Browser console for errors (F12)

Good luck! Your portfolio is ready to impress! 🎉
