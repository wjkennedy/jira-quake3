#!/bin/bash

set -e

echo "=========================================="
echo "DOOM Forge App - Build Script"
echo "=========================================="
echo ""

# Check if Emscripten is installed
if ! command -v emcc &> /dev/null; then
    echo "Error: Emscripten is not installed or not in PATH"
    echo ""
    echo "Please install Emscripten:"
    echo "  macOS: brew install emscripten"
    echo "  Linux: Follow instructions at https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
fi

echo "✓ Emscripten found: $(emcc --version | head -n 1)"
echo ""

# Create build directory if it doesn't exist
mkdir -p build

# Clone doomgeneric if not present
if [ ! -d "build/doomgeneric" ]; then
    echo "Cloning doomgeneric repository..."
    git clone https://github.com/ozkl/doomgeneric.git build/doomgeneric
    echo "✓ Repository cloned"
else
    echo "✓ doomgeneric repository already exists"
fi

cd build/doomgeneric/doomgeneric

# Download doom1.wad if not present
if [ ! -f "doom1.wad" ]; then
    echo ""
    echo "Downloading doom1.wad (shareware version)..."
    
    # Try primary source
    if wget -q https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad; then
        echo "✓ doom1.wad downloaded"
    else
        echo "Primary source failed, trying alternate source..."
        # Try alternate source
        if wget -q -O doom1.wad.zip http://www.doomworld.com/3ddownloads/ports/shareware_doom_iwad.zip; then
            unzip -q doom1.wad.zip
            rm doom1.wad.zip
            echo "✓ doom1.wad downloaded and extracted"
        else
            echo ""
            echo "Error: Could not download doom1.wad automatically"
            echo "Please download it manually from:"
            echo "  - https://archive.org/details/DoomsharewareEpisode"
            echo "  - https://doomwiki.org/wiki/DOOM1.WAD"
            echo ""
            echo "Place doom1.wad in: build/doomgeneric/doomgeneric/"
            exit 1
        fi
    fi
else
    echo "✓ doom1.wad already exists"
fi

# Verify doom1.wad
WAD_SIZE=$(stat -f%z doom1.wad 2>/dev/null || stat -c%s doom1.wad 2>/dev/null)
if [ "$WAD_SIZE" -lt 4000000 ]; then
    echo "Error: doom1.wad seems too small ($(($WAD_SIZE / 1024))KB). Expected ~4.2MB"
    echo "Please download a valid doom1.wad file"
    exit 1
fi

echo "✓ doom1.wad is valid ($(($WAD_SIZE / 1024 / 1024))MB)"

# Build with Emscripten
echo ""
echo "Building DOOM WebAssembly files..."
echo "This may take a few minutes..."
echo ""

make -f Makefile.emscripten

if [ $? -ne 0 ]; then
    echo ""
    echo "Error: Build failed"
    echo "Check the error messages above for details"
    exit 1
fi

echo ""
echo "✓ Build completed successfully"

# Go back to project root
cd ../../..

# Create static/doom directory if it doesn't exist
mkdir -p static/doom

# Copy files
echo ""
echo "Copying files to Forge app..."

cp build/doomgeneric/doomgeneric/doomgeneric.js static/doom/
cp build/doomgeneric/doomgeneric/doomgeneric.wasm static/doom/
cp build/doomgeneric/doomgeneric/doomgeneric.data static/doom/

echo "✓ Files copied to static/doom/"

# Verify files
echo ""
echo "Verifying files..."
echo ""

if [ -f "static/doom/doomgeneric.js" ]; then
    JS_SIZE=$(stat -f%z static/doom/doomgeneric.js 2>/dev/null || stat -c%s static/doom/doomgeneric.js 2>/dev/null)
    echo "  doomgeneric.js: $(($JS_SIZE / 1024))KB ✓"
else
    echo "  doomgeneric.js: MISSING ✗"
fi

if [ -f "static/doom/doomgeneric.wasm" ]; then
    WASM_SIZE=$(stat -f%z static/doom/doomgeneric.wasm 2>/dev/null || stat -c%s static/doom/doomgeneric.wasm 2>/dev/null)
    echo "  doomgeneric.wasm: $(($WASM_SIZE / 1024 / 1024))MB ✓"
else
    echo "  doomgeneric.wasm: MISSING ✗"
fi

if [ -f "static/doom/doomgeneric.data" ]; then
    DATA_SIZE=$(stat -f%z static/doom/doomgeneric.data 2>/dev/null || stat -c%s static/doom/doomgeneric.data 2>/dev/null)
    echo "  doomgeneric.data: $(($DATA_SIZE / 1024 / 1024))MB ✓"
else
    echo "  doomgeneric.data: MISSING ✗"
fi

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Your DOOM Forge app is ready to deploy!"
echo ""
echo "Next steps:"
echo "  1. Test locally:  forge tunnel"
echo "  2. Deploy:        forge deploy"
echo "  3. Install:       forge install"
echo ""
