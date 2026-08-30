===============================================================
 JUSTIN TANG PHOTOGRAPHY  -  cogroup.studio
 How to run your website. Last updated 10 Aug 2026.
===============================================================

There are only THREE things you will ever do:

   A. Change some wording        -> edit content.txt
   B. Add or remove photos       -> drag files into images\
   C. Publish it                 -> UPDATE WEBSITE.bat, then push

Everything else is automatic.


===============================================================
 FOLDER LAYOUT
===============================================================

   Website\
   |
   |-- UPDATE WEBSITE.bat     <<< RUN THIS after any change
   |-- content.txt            <<< EDIT THIS to change wording
   |-- README - START HERE.txt    (this file)
   |
   |-- images\                <<< PUT PHOTOS HERE
   |     |-- projects\<name>\4x5\      your project photos
   |     |-- gallery\4x5\              standalone gallery photos
   |     |-- main_page\background\     homepage hero photos
   |     \-- ...\thumbs\               AUTO-MADE. Never touch.
   |
   |-- _scripts\              <<< IGNORE THIS FOLDER ENTIRELY
   |                              (the machinery. Don't open it.)
   |
   \-- the .html / .css / .js files
                              <<< DON'T EDIT THESE BY HAND
                                  They get rebuilt automatically.
                                  They must stay in this top folder
                                  or GitHub Pages won't find them.

Rule of thumb: you touch content.txt, images\, and the .bat.
Nothing else.


===============================================================
 A. CHANGING WORDING
===============================================================

1. Open  content.txt  (double-click, opens in Notepad)
2. Change the text UNDER any [heading]
3. Save
4. Double-click  UPDATE WEBSITE.bat

Rules:
  - NEVER change the [heading] lines. They tell the script where
    the text belongs.
  - Lines starting with # are notes, ignored.
  - Keep each piece of text on ONE line.
  - To write an & symbol, just type &

If you typo a [heading], the script tells you which one didn't
match. It won't fail silently.


===============================================================
 B. ADDING AND REMOVING PHOTOS
===============================================================

TO ADD PHOTOS
  1. Drop them into the right folder:

       images\projects\<project name>\4x5\    (or 5x4 / 16x9)
       images\gallery\4x5\                    (or 5x4 / 16x9)

     Export at whatever size you like from Lightroom. The
     updater shrinks anything bigger than 2000px on the long
     edge automatically, before it ever reaches the website.
     Never put anything in a "thumbs" folder.

  2. Double-click  UPDATE WEBSITE.bat

TO REMOVE PHOTOS
  1. Delete the photo from the folder (normal Windows delete)
  2. Double-click  UPDATE WEBSITE.bat

     It removes the leftover thumbnail and takes the photo off
     every page automatically.

TO ADD A WHOLE NEW PROJECT
  1. Make the folder:   images\projects\<new name>\4x5\
  2. Copy any existing project-*.html, rename it to
     project-<new name>.html, and change the title inside
  3. Run UPDATE WEBSITE.bat

     If you forget step 2, the script tells you exactly which
     folder has no page yet.


===============================================================
 C. PUBLISHING TO GITHUB  (making it go live)
===============================================================

Your site is at https://cogroup.studio and lives in the GitHub
repo:  justinm3urphy/justinphotographywebsite

STEP 1 - Run the updater
     Double-click  UPDATE WEBSITE.bat
     Wait for "DONE." and check nothing is listed as a PROBLEM.

STEP 2 - Look at it yourself
     Double-click index.html and gallery.html to open them in
     your browser. Click a photo to check the lightbox works.
     ALWAYS do this. The site is live - mistakes go public.

STEP 3 - Push it

     Open a terminal IN THIS FOLDER. Easiest way:
     click the address bar in File Explorer, type  cmd  , Enter.

     Then run these three, one at a time:

         git add .
         git commit -m "Added new automotive photos"
         git push

     What they do:
         git add .        gathers up everything you changed
         git commit -m    saves it with a note describing it
         git push         uploads it to GitHub

     Change the message in quotes to whatever you did.

STEP 4 - Wait about 60 seconds
     GitHub rebuilds the site automatically. Then open
     https://cogroup.studio and confirm your change is live.
     If you don't see it, hard-refresh with Ctrl+F5.


THINGS THAT WILL COME UP
------------------------

"git is not recognized"
     Git isn't installed on that machine. Get it from
     https://git-scm.com/download/win  - accept all defaults.
     Or use GitHub Desktop (https://desktop.github.com) which
     gives you buttons instead of commands: it shows your changed
     files, you type a message, click "Commit", then "Push".

It asks who I am (first time only)
         git config --global user.name "Justin Tang"
         git config --global user.email "justintangapple@gmail.com"

It lists a LOT of changed files
     Expected the first time - the thumbnails alone are 214 new
     files, plus every page was rebuilt. That's normal.

"failed to push / rejected"
     Someone (or another machine) changed the repo since you last
     pulled. Run  git pull  first, then push again.

I want to see what changed before committing
         git status          lists changed files
         git diff            shows the actual changes


===============================================================
 PHOTO SIZES  (why you can export big from Lightroom)
===============================================================

You do not need to think about export size any more.

UPDATE WEBSITE.bat now shrinks photos for you, in this order:

  1. Any photo over 2000px on the long edge is resized down to
     2000px and saved at quality 85.
  2. Anything still over 2MB is re-encoded.
  3. Everything else is left completely alone.
  4. Then thumbnails (600px) are made from the result.

So a 6000px, 3MB Lightroom export becomes about 400KB before it
ever reaches the site. Tested: 3,248 KB -> 387 KB.

TWO THINGS WORTH KNOWING

  - It edits the photo in the images\ folder IN PLACE. Your
    Lightroom catalogue is the master copy - the website folder
    is not a backup, and never was.

  - Each photo is processed ONCE. A record is kept in
    _scripts\.optimized.json so the same photo is never
    re-compressed twice. That matters: every JPEG re-encode
    loses a little quality, and doing it on every build would
    slowly degrade your whole library.

Photos already on the site are untouched - they are all within
the limits already.

===============================================================
 MOBILE
===============================================================

The site was already built responsive - 6 screen-size
breakpoints, a bottom nav bar on phones, iPhone notch handling.
That part was done well.

The thumbnails matter most on mobile. Browsing your gallery on a
phone used to download 122 MB. It now downloads 8.6 MB, with no
visible quality loss - the grid photos are only ~110px wide on a
phone, and the thumbnails are 600px.

UPDATE WEBSITE.bat checks the mobile essentials every run:
  - every page has a viewport tag (without it, phones show the
    desktop layout shrunk to unreadable)
  - every page loads styles.css and has the bottom nav
  - the bottom nav is identical on all pages
  - all grid photos use thumbnails
  - every image link points at a file that exists

Still open it on your actual phone before pushing. A script can
check structure; it can't tell you if something looks wrong.

Possible tweak: the gallery shows 3 columns on a phone, which
makes the photos quite small. 2 columns would give them more
room. One line of CSS if you want it.


===============================================================
 WHAT WAS WRONG BEFORE (all fixed)
===============================================================

1. sync-website.ps1 COULD NOT RUN AT ALL.
   Four PowerShell syntax errors - it failed instantly, every
   time. So any photos you added were never picked up. Rewritten.

2. THE PROJECT LIST WAS HARDCODED.
   A new project folder would have been silently ignored. It now
   detects folders automatically and warns about missing pages.

3. DEAD HERO CODE.
   The sync script looked for an image path that doesn't exist,
   so it did nothing. (Your hero still rotated - script.js does
   that in the browser. This was dead code, not a broken feature.)

4. FOOTER INCONSISTENCIES.
   projects.html had lowercase "built with google antigravity"
   and was missing the social links the other 9 pages had.

5. THE MOBILE NAV BAR DIDN'T MATCH BETWEEN PAGES.
   "meet me" had an icon on one page only, so the bar changed as
   you navigated on a phone.

6. GRIDS LOADED FULL-SIZE PHOTOS.
   gallery.html made a visitor download 122 MB. Now 8.6 MB.
   Your original photos were never modified - clicking a photo
   still opens the full-resolution file.

7. Optimize-Images.ps1 DID NOTHING (now rewritten).
   The old one only acted on files over 1 MB AND wider than
   2000px, so it skipped every photo while reporting success.
   It has been replaced with a working version that runs as
   part of the updater - see PHOTO SIZES below.


===============================================================
 IF SOMETHING GOES WRONG
===============================================================

There is a backup of every code file (not the photos) at:

    Website_BACKUP_2026-08-10

That is the site exactly as it was before any of these changes.
Copy those files back over the top and you're where you started.

If you already pushed something bad, you can undo the last
commit with:

    git revert HEAD
    git push

That publishes an "undo" rather than erasing history, which is
the safe option.


===============================================================
 MOVING THIS FOLDER TO ANOTHER PC
===============================================================

Everything uses relative paths. Zip it, move it, unzip anywhere -
it still works. Only needs Windows PowerShell, which every
Windows PC already has. Nothing to install.

Two things:

1. Windows sometimes BLOCKS scripts that came out of a zip.
   If a .bat won't run: right-click it -> Properties ->
   tick "Unblock" -> OK.

2. If the PC you're copying TO has newer work than this copy,
   copying over the top will destroy it. Check first.

===============================================================
