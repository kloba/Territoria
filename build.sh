#!/bin/bash
set -e

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter doctor..."
flutter doctor

echo "Getting dependencies..."
flutter pub get

echo "Building for web..."
flutter build web --release --web-renderer html

echo "Build complete!"