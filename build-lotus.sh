#!/bin/bash

set -e

echo "=========================================="
echo "Lotus 1-2-3 Forge App - Build Script"
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

# Clone dosbox repository if not present
if [ ! -d "build/dosbox" ]; then
    echo "Cloning DOSBox repository..."
    git clone https://github.com/dreamlayers/em-dosbox.git build/dosbox
    echo "✓ Repository cloned"
else
    echo "✓ DOSBox repository already exists"
fi

cd build/dosbox

# Download Lotus 1-2-3 Release 2.4 if not present
if [ ! -f "lotus.zip" ]; then
    echo ""
    echo "Downloading Lotus 1-2-3..."
    echo ""
    echo "NOTE: Lotus 1-2-3 is commercial software. You need a legal copy."
    echo "For testing purposes, you can use:"
    echo "  - Archive.org: https://archive.org/details/Lotus_1-2-3_Release_2.4"
    echo "  - WinWorld: https://winworldpc.com/product/lotus-1-2-3/2x"
    echo ""
    echo "Attempting to download from Archive.org..."
    
    if wget -q -O lotus.zip "https://archive.org/download/Lotus_1-2-3_Release_2.4/Lotus123_R24.zip"; then
        echo "✓ Lotus 1-2-3 downloaded"
        mkdir -p lotus
        unzip -q lotus.zip -d lotus
        echo "✓ Lotus 1-2-3 extracted"
    else
        echo ""
        echo "Automatic download failed."
        echo "Please download Lotus 1-2-3 manually and extract to: build/dosbox/lotus/"
        echo ""
        echo "Expected structure:"
        echo "  build/dosbox/lotus/123.EXE"
        echo "  build/dosbox/lotus/*.HLP"
        echo "  build/dosbox/lotus/*.DRV"
        exit 1
    fi
else
    echo "✓ Lotus 1-2-3 archive already exists"
fi

# Verify lotus files
if [ ! -d "lotus" ] || [ ! -f "lotus/123.EXE" ]; then
    echo ""
    echo "Error: Lotus 1-2-3 files not found in build/dosbox/lotus/"
    echo "Please ensure 123.EXE exists in build/dosbox/lotus/"
    exit 1
fi

echo "✓ Lotus 1-2-3 files verified"

# Build DOSBox with Emscripten
echo ""
echo "Building DOSBox WebAssembly files..."
echo "This may take several minutes..."
echo ""

# Configure for Emscripten build
if [ ! -f "Makefile" ]; then
    emconfigure ./configure
fi

emmake make

if [ $? -ne 0 ]; then
    echo ""
    echo "Error: Build failed"
    echo "Check the error messages above for details"
    exit 1
fi

echo ""
echo "✓ Build completed successfully"

# Create dosbox filesystem bundle
echo ""
echo "Creating filesystem bundle..."

mkdir -p dosbox_fs/C
cp -r lotus/* dosbox_fs/C/

# Create autoexec.bat to launch Lotus automatically
cat > dosbox_fs/autoexec.bat << 'EOF'
@echo off
mount C .
C:
cd \
123.exe
EOF

# Package filesystem
python3 ../../package_dosbox_fs.py dosbox_fs dosbox_fs.data

echo "✓ Filesystem bundle created"

# Go back to project root
cd ../..

# Create static/lotus123 directory if it doesn't exist
mkdir -p static/lotus123

# Copy files
echo ""
echo "Copying files to Forge app..."

cp build/dosbox/dosbox.js static/lotus123/
cp build/dosbox/dosbox.wasm static/lotus123/
cp build/dosbox/dosbox_fs.data static/lotus123/

echo "✓ Files copied to static/lotus123/"

# Verify files
echo ""
echo "Verifying files..."
echo ""

if [ -f "static/lotus123/dosbox.js" ]; then
    JS_SIZE=$(stat -f%z static/lotus123/dosbox.js 2>/dev/null || stat -c%s static/lotus123/dosbox.js 2>/dev/null)
    echo "  dosbox.js: $(($JS_SIZE / 1024))KB ✓"
else
    echo "  dosbox.js: MISSING ✗"
fi

if [ -f "static/lotus123/dosbox.wasm" ]; then
    WASM_SIZE=$(stat -f%z static/lotus123/dosbox.wasm 2>/dev/null || stat -c%s static/lotus123/dosbox.wasm 2>/dev/null)
    echo "  dosbox.wasm: $(($WASM_SIZE / 1024 / 1024))MB ✓"
else
    echo "  dosbox.wasm: MISSING ✗"
fi

if [ -f "static/lotus123/dosbox_fs.data" ]; then
    DATA_SIZE=$(stat -f%z static/lotus123/dosbox_fs.data 2>/dev/null || stat -c%s static/lotus123/dosbox_fs.data 2>/dev/null)
    echo "  dosbox_fs.data: $(($DATA_SIZE / 1024 / 1024))MB ✓"
else
    echo "  dosbox_fs.data: MISSING ✗"
fi

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Your Lotus 1-2-3 Forge app is ready to deploy!"
echo ""
echo "Next steps:"
echo "  1. Test locally:  forge tunnel"
echo "  2. Deploy:        forge deploy"
echo "  3. Install:       forge install"
echo ""
echo "Note: The app currently uses a JavaScript spreadsheet engine."
echo "To use authentic Lotus 1-2-3, you need to build DOSBox WASM."
echo "See DOSBOX_BUILD_INSTRUCTIONS.md for details."
echo ""
