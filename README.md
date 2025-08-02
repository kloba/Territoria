# Territoria

A GPS-based territory capture game PWA built with Flutter Web. Walk around to capture real-world territory in a Paper.io-style gameplay experience.

## Features

- Real GPS tracking with location-based gameplay
- Territory capture by walking outside your zone and returning
- Daily statistics tracking (distance, steps, area captured)
- Progressive Web App - installable on mobile devices
- Offline data persistence
- Clean, responsive UI with real-time map updates

## Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Chrome browser for web development
- HTTPS server for PWA deployment

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/territoria.git
cd territoria
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate required files (Hive adapters):
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

4. Add app icons to `web/icons/` directory:
   - Icon-192.png (192x192)
   - Icon-512.png (512x512)
   - Icon-maskable-192.png (192x192)
   - Icon-maskable-512.png (512x512)

## Running the App

### Development

```bash
flutter run -d chrome --web-renderer html
```

Note: Use `--web-renderer html` for better GPS support in browsers.

### Building for Production

```bash
flutter build web --web-renderer html --release
```

The built files will be in `build/web/` directory.

### Deployment

1. Deploy the `build/web/` directory to an HTTPS-enabled server
2. Ensure the server includes proper headers for PWA support
3. Test installation on mobile devices

## Architecture

- **State Management**: Provider pattern
- **Data Persistence**: Hive for web (IndexedDB)
- **Map Rendering**: flutter_map with OpenStreetMap tiles
- **Game Graphics**: CustomPaint for zone and trail rendering
- **Geometry Operations**: turf_dart for polygon operations

## Game Rules

1. Start with a small circular zone around your starting position
2. Walk outside your zone to start drawing a trail
3. Return to your zone to capture the area enclosed by your trail
4. Minimum capture area: 150 m²
5. Minimum trail vertices: 10 points

## Permissions

The app requires location permission (foreground only) to track movement and enable gameplay.

## License

MIT License