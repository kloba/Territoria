# Deploy Territoria Without Local Flutter

## Option 1: GitHub Pages (Recommended)

1. Create a GitHub repository:
   ```bash
   cd /Users/tk/repos/Territoria
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. Create a new repo on GitHub.com and push:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/Territoria.git
   git branch -M main
   git push -u origin main
   ```

3. The GitHub Action will automatically build and deploy to:
   `https://YOUR_USERNAME.github.io/Territoria/`

4. Enable GitHub Pages in repo settings:
   - Go to Settings → Pages
   - Source: Deploy from a branch
   - Branch: gh-pages
   - Folder: / (root)

## Option 2: Netlify (Easiest)

1. Push to GitHub (steps above)
2. Go to [netlify.com](https://netlify.com)
3. Click "Add new site" → "Import an existing project"
4. Connect GitHub and select your repo
5. Build settings:
   - Build command: `flutter build web --release --web-renderer html`
   - Publish directory: `build/web`
6. Click "Deploy site"

## Option 3: Vercel

1. Push to GitHub
2. Go to [vercel.com](https://vercel.com)
3. Import your GitHub repository
4. Framework Preset: Other
5. Build Command: `flutter build web --release --web-renderer html`
6. Output Directory: `build/web`
7. Install Command: `flutter pub get`

## Option 4: Cloudflare Pages

1. Push to GitHub
2. Go to [pages.cloudflare.com](https://pages.cloudflare.com)
3. Create a project → Connect to Git
4. Build settings:
   - Build command: `flutter build web --release --web-renderer html`
   - Build output directory: `build/web`

## Option 5: CodeSandbox

1. Go to [codesandbox.io](https://codesandbox.io)
2. Create new → Import from GitHub
3. It will detect Flutter and set up the environment
4. The app will run in the browser

## Option 6: StackBlitz

1. Go to `https://stackblitz.com/github/YOUR_USERNAME/Territoria`
2. It will automatically set up Flutter environment
3. Run in the browser

## Important Notes

- The app requires HTTPS for GPS/location features to work
- Mobile browsers may have restrictions on PWA installation
- Test on your phone using the deployed URL

The easiest options are Netlify or GitHub Pages as they handle everything automatically!