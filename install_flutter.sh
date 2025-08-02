#!/bin/bash

echo "Flutter Installation Script for macOS"
echo "===================================="
echo ""
echo "This script will help you install Flutter for the Territoria project."
echo ""

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.32.8-stable.zip"
    echo "Detected Apple Silicon (M1/M2) Mac"
else
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.32.8-stable.zip"
    echo "Detected Intel Mac"
fi

echo ""
echo "Steps to install Flutter:"
echo ""
echo "1. Download Flutter SDK:"
echo "   curl -O $FLUTTER_URL"
echo ""
echo "2. Extract Flutter:"
echo "   unzip flutter_macos_*.zip"
echo ""
echo "3. Add Flutter to PATH by adding this to ~/.zshrc or ~/.bash_profile:"
echo "   export PATH=\"\$PATH:\$HOME/flutter/bin\""
echo ""
echo "4. Run Flutter doctor:"
echo "   flutter doctor"
echo ""
echo "5. Accept licenses:"
echo "   flutter doctor --android-licenses"
echo ""
echo "Alternative: Install with Homebrew (may be slower):"
echo "   brew install --cask flutter"
echo ""
echo "After installation, navigate to the Territoria directory and run:"
echo "   cd /Users/tk/repos/Territoria"
echo "   flutter pub get"
echo "   flutter run -d chrome --web-renderer html"