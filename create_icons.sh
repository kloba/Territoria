#!/bin/bash

# Create a simple SVG icon
cat > icon.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192">
  <rect width="192" height="192" fill="#1976d2"/>
  <text x="96" y="96" text-anchor="middle" dominant-baseline="middle" 
        font-family="Arial" font-size="120" font-weight="bold" fill="white">T</text>
</svg>
EOF

# Create icon files (requires ImageMagick)
# For now, just create placeholder files
echo "Creating placeholder icon files..."
mkdir -p web/icons
echo "Placeholder icon 192x192" > web/icons/Icon-192.png
echo "Placeholder icon 512x512" > web/icons/Icon-512.png
echo "Placeholder icon maskable 192x192" > web/icons/Icon-maskable-192.png
echo "Placeholder icon maskable 512x512" > web/icons/Icon-maskable-512.png

echo "Icon placeholders created. For real icons, use ImageMagick:"
echo "convert icon.svg -resize 192x192 web/icons/Icon-192.png"
echo "convert icon.svg -resize 512x512 web/icons/Icon-512.png"