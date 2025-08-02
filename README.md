# Territoria - GPS Territory Capture Game

A simple, lightweight Progressive Web App (PWA) that lets you capture real-world territory by walking around with GPS.

## Features

- 🗺️ **Real-time GPS tracking** - See your position on an OpenStreetMap
- 🏃 **Territory capture** - Walk outside your zone to create trails, return to capture
- 📊 **Live statistics** - Track distance walked, territory size, and captures
- 📱 **PWA support** - Install on your phone for native-like experience
- 🎯 **Simple gameplay** - No accounts, no servers, just walk and capture

## Live Demo

Visit: https://kloba.github.io/Territoria/

## How to Play

1. **Grant location permission** when prompted
2. **Blue circle** is your territory (starts at 20m radius)
3. **Walk outside** your territory to start recording a trail (red line)
4. **Return to your territory** to capture the area
5. **Expand** your territory with each capture

## Technical Details

### Architecture
- **Flutter Web** - Single page application
- **Minimal dependencies** - Only essential packages
- **No backend** - Everything runs locally
- **Simple state management** - No complex patterns

### Dependencies
- `flutter_map` - Map rendering
- `geolocator` - GPS tracking
- `latlong2` - Coordinate handling

## Development

### Prerequisites
- Flutter SDK 3.0+
- Chrome browser

### Running locally
```bash
# Install dependencies
flutter pub get

# Run in Chrome
flutter run -d chrome --web-renderer html
```

### Building for production
```bash
# Build optimized version
flutter build web --release --web-renderer html

# Deploy the build/web directory
```

## Deployment

The app is automatically deployed to GitHub Pages via GitHub Actions on push to main branch.

### Manual deployment options:
1. **GitHub Pages** - Push to gh-pages branch
2. **Netlify** - Drop build/web folder
3. **Vercel** - Import GitHub repo
4. **Any static host** - Upload build/web contents

## Browser Support

- ✅ Chrome/Edge (Recommended)
- ✅ Safari iOS 
- ✅ Firefox
- ✅ Samsung Internet

## Privacy

- No data collection
- No accounts required  
- GPS data stays on device
- No external analytics

## License

MIT License - See LICENSE file