#!/bin/bash

# Qwasm Build Script for Forge App Integration
# This script automates the process of building Qwasm and preparing it for the Forge app

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Qwasm Build Script for Forge App${NC}"
echo "========================================"

# Configuration
QWASM_REPO="https://github.com/GMH-Code/Qwasm.git"
QWASM_DIR="./qwasm-build"
FORGE_STATIC_DIR="./static/quake"
BUILD_TYPE="${1:-software}"  # software or webgl

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Emscripten is installed
if ! command -v emcc &> /dev/null; then
    print_error "Emscripten is not installed or not in PATH"
    print_info "Please install Emscripten first:"
    echo "  cd /path/to/emsdk"
    echo "  ./emsdk install latest"
    echo "  ./emsdk activate latest"
    echo "  source ./emsdk_env.sh"
    exit 1
fi

print_info "Emscripten found: $(emcc --version | head -n 1)"

# Clone or update Qwasm repository
if [ -d "$QWASM_DIR" ]; then
    print_info "Qwasm directory exists, pulling latest changes..."
    cd "$QWASM_DIR"
    git pull
    cd ..
else
    print_info "Cloning Qwasm repository..."
    git clone "$QWASM_REPO" "$QWASM_DIR"
fi

# Check for PAK files
PAK_DIR="$QWASM_DIR/WinQuake/id1"
mkdir -p "$PAK_DIR"

if [ ! -f "$PAK_DIR/pak0.pak" ]; then
    print_warning "pak0.pak not found in $PAK_DIR"
    print_info "Please add your Quake PAK files to: $PAK_DIR"
    print_info "Files must be lowercase (pak0.pak, pak1.pak)"
    print_info "See QWASM_BUILD_INSTRUCTIONS.md for details on obtaining PAK files"
    exit 1
fi

print_info "Found pak0.pak"

if [ -f "$PAK_DIR/pak1.pak" ]; then
    print_info "Found pak1.pak (full version)"
else
    print_warning "pak1.pak not found (shareware version only)"
fi

# Build Qwasm
cd "$QWASM_DIR/WinQuake"

if [ "$BUILD_TYPE" = "webgl" ]; then
    print_info "Building hardware-rendered version (WebGL)..."
    
    # Check for GL4ES
    if [ -z "$GL4ES_PATH" ]; then
        print_error "GL4ES_PATH not set for WebGL build"
        print_info "Please set GL4ES_PATH or run with 'software' argument"
        exit 1
    fi
    
    make -f Makefile.emscripten GL4ES_PATH="$GL4ES_PATH"
else
    print_info "Building software-rendered version..."
    make -f Makefile.emscripten
fi

# Create static directory if it doesn't exist
cd ../..
mkdir -p "$FORGE_STATIC_DIR"

# Copy build output
print_info "Copying build output to Forge app..."
cp "$QWASM_DIR/WinQuake/index.js" "$FORGE_STATIC_DIR/"
cp "$QWASM_DIR/WinQuake/index.wasm" "$FORGE_STATIC_DIR/"
cp "$QWASM_DIR/WinQuake/index.data" "$FORGE_STATIC_DIR/"

# Verify files were copied
if [ -f "$FORGE_STATIC_DIR/index.js" ] && \
   [ -f "$FORGE_STATIC_DIR/index.wasm" ] && \
   [ -f "$FORGE_STATIC_DIR/index.data" ]; then
    print_info "Build files successfully copied!"
else
    print_error "Failed to copy some build files"
    exit 1
fi

# Show file sizes
print_info "Build file sizes:"
ls -lh "$FORGE_STATIC_DIR/index.js" | awk '{print "  index.js:   " $5}'
ls -lh "$FORGE_STATIC_DIR/index.wasm" | awk '{print "  index.wasm: " $5}'
ls -lh "$FORGE_STATIC_DIR/index.data" | awk '{print "  index.data: " $5}'

# Compress files (optional)
if command -v gzip &> /dev/null; then
    print_info "Compressing files with gzip..."
    gzip -9 -k "$FORGE_STATIC_DIR/index.wasm"
    gzip -9 -k "$FORGE_STATIC_DIR/index.data"
    print_info "Compressed files created (.gz)"
fi

echo ""
print_info "${GREEN}Build complete!${NC}"
echo ""
print_info "Next steps:"
echo "  1. Verify the following files exist:"
echo "     - $FORGE_STATIC_DIR/index.html"
echo "     - $FORGE_STATIC_DIR/styles.css"
echo "     - $FORGE_STATIC_DIR/quake-logo.png (optional)"
echo "  2. Run 'forge deploy' to deploy your app"
echo ""
print_info "To test locally, you can use a local web server:"
echo "  cd $FORGE_STATIC_DIR && python3 -m http.server 8000"
echo ""
