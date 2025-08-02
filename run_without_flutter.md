# Running Territoria Without Flutter SDK

Since Flutter installation is taking too long, here are alternative ways to run the project:

## Option 1: Use Flutter in Browser (DartPad)
Unfortunately, DartPad doesn't support external packages, so this won't work for our full app.

## Option 2: Use GitHub Codespaces or Gitpod
1. Push the code to GitHub
2. Open in GitHub Codespaces or Gitpod (they have Flutter pre-installed)
3. Run the project there

## Option 3: Quick Local Installation
Run the installation script:
```bash
./install_flutter.sh
```

Then follow the manual steps it provides.

## Option 4: Docker (if you have Docker installed)
```bash
docker run --rm -it -v $(pwd):/app -w /app -p 8080:8080 cirrusci/flutter:stable flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

## What the App Does
The Territoria PWA is a GPS-based territory capture game that:
- Uses your real location to let you "capture" territory by walking
- Shows a map with your current position
- Draws trails as you walk outside your territory
- Captures new area when you return to your zone
- Tracks daily statistics (distance walked, steps, area captured)
- Works as a Progressive Web App installable on phones

The complete source code is ready in the project directory!