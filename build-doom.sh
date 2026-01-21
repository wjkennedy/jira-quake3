#!/bin/bash

set -e

echo "=========================================="
echo "DOOM Forge App - Build Script (Dwasm)"
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

# Check for cmake
if ! command -v cmake &> /dev/null; then
    echo "Error: cmake is not installed"
    echo ""
    echo "Please install cmake:"
    echo "  macOS: brew install cmake"
    echo "  Linux: apt-get install cmake"
    exit 1
fi

echo "✓ cmake found: $(cmake --version | head -n 1)"
echo ""

# Create build directory
mkdir -p build

# Clone Dwasm if not present
if [ ! -d "build/Dwasm" ]; then
    echo "Cloning Dwasm repository (PrBoom+ based DOOM with sound & music)..."
    git clone https://github.com/GMH-Code/Dwasm.git build/Dwasm
    echo "✓ Repository cloned"
else
    echo "✓ Dwasm repository already exists"
fi

cd build/Dwasm

# Create wasm/fs directory for WAD files
mkdir -p wasm/fs

# Check for prboomx.wad - need to build native first
if [ ! -f "wasm/fs/prboomx.wad" ]; then
    echo ""
    echo "Building native PrBoomX to generate prboomx.wad..."
    
    mkdir -p build_native
    cd build_native
    cmake .. -DCMAKE_BUILD_TYPE=Release 2>/dev/null || true
    make prboom-plus-wad 2>/dev/null || make 2>/dev/null || true
    cd ..
    
    # Find and copy prboomx.wad
    PRBOOM_WAD=$(find . -name "prboomx.wad" -o -name "prboom-plus.wad" 2>/dev/null | head -1)
    if [ -n "$PRBOOM_WAD" ]; then
        cp "$PRBOOM_WAD" wasm/fs/prboomx.wad
        echo "✓ prboomx.wad generated"
    else
        echo "Warning: Could not generate prboomx.wad, trying to download..."
        # Try to download a pre-built one
        curl -sL -o wasm/fs/prboomx.wad "https://github.com/GMH-Code/Dwasm/raw/main/wasm/fs/prboomx.wad" 2>/dev/null || true
    fi
fi

# Download doom1.wad if not present
if [ ! -f "wasm/fs/doom1.wad" ]; then
    echo ""
    echo "Downloading doom1.wad (shareware version)..."
    
    if wget -q -O wasm/fs/doom1.wad https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad; then
        echo "✓ doom1.wad downloaded"
    else
        echo "Error: Could not download doom1.wad"
        echo "Please download it manually and place in build/Dwasm/wasm/fs/"
        exit 1
    fi
else
    echo "✓ doom1.wad already exists"
fi

# Verify doom1.wad
WAD_SIZE=$(stat -f%z wasm/fs/doom1.wad 2>/dev/null || stat -c%s wasm/fs/doom1.wad 2>/dev/null)
if [ "$WAD_SIZE" -lt 4000000 ]; then
    echo "Warning: doom1.wad seems small ($(($WAD_SIZE / 1024))KB)"
    echo "Shareware version is ~4.2MB, full version is larger"
fi

echo ""
echo "Building Dwasm WebAssembly..."
echo "This may take several minutes..."
echo ""

# Create the WASM build directory
mkdir -p build_wasm
cd build_wasm

# Run emcmake cmake
emcmake cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

if [ $? -ne 0 ]; then
    echo ""
    echo "Error: Build failed"
    exit 1
fi

echo ""
echo "✓ Build completed successfully"

# Go back to project root
cd ../../..

# Create static/doom directory
mkdir -p static/doom

# Copy Dwasm output files
echo ""
echo "Copying files to Forge app..."

# Dwasm outputs to build_wasm folder
if [ -f "build/Dwasm/build_wasm/index.js" ]; then
    cp build/Dwasm/build_wasm/index.js static/doom/index.js
    cp build/Dwasm/build_wasm/index.wasm static/doom/index.wasm
    cp build/Dwasm/build_wasm/index.data static/doom/index.data
    
    # Also copy HTML if available for reference
    cp build/Dwasm/build_wasm/index.html static/doom/dwasm-original.html 2>/dev/null || true
    
    echo "✓ Files copied to static/doom/"
else
    echo "Error: Build output not found"
    echo "Looking for files..."
    find build/Dwasm -name "*.wasm" -o -name "*.js" | head -10
    exit 1
fi

# Verify files
echo ""
echo "Verifying files..."

for file in index.js index.wasm index.data; do
    if [ -f "static/doom/$file" ]; then
        SIZE=$(stat -f%z "static/doom/$file" 2>/dev/null || stat -c%s "static/doom/$file" 2>/dev/null)
        echo "  $file: $(($SIZE / 1024))KB ✓"
    else
        echo "  $file: MISSING ✗"
    fi
done

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Dwasm features:"
echo "  ✓ Full sound effects via SDL2"
echo "  ✓ MIDI music via OPL2 synthesizer (Sound Blaster style)"
echo "  ✓ Widescreen support"
echo "  ✓ Higher resolutions and framerates"
echo ""
echo "Next steps:"
echo "  1. Test locally:  forge tunnel"
echo "  2. Deploy:        forge deploy"
echo ""
