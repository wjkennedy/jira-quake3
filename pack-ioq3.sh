#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}ioquake3 Build Script for Forge App${NC}"
echo "========================================"

# Configuration
IOQ3_REPO="https://github.com/wjkennedy/jioq3"
IOQ3_DIR="./ioq3-build"
FORGE_STATIC_DIR="./static/quake3"
BUILD_DIR="$IOQ3_DIR/build/emscripten"

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
if [ -f "$PAK_DIR/pak1.pk3" ]; then
    echo "Found pak1.pk3 (full version)"
else
    echo "pak1.pk3 not found (demo/shareware version only)"
fi

# Build ioquake3 with Emscripten
echo "Configuring ioquake3 build..."
mkdir -p "$BUILD_DIR"

if [ -f "$IOQ3_DIR/Makefile" ]; then
    echo "Makefile detected, building with emmake..."
    cd "$IOQ3_DIR"
    emmake make
else
    echo "CMake project detected, building with emcmake..."
    emcmake cmake -S "$IOQ3_DIR" -B "$BUILD_DIR"
    cmake --build "$BUILD_DIR"
fi

# Create static directory if it doesn't exist
mkdir -p "$FORGE_STATIC_DIR"

echo "Copying build output to Forge app..."
PREF_JS="$BUILD_DIR/Release/ioquake3.js"
PREF_WASM="$BUILD_DIR/Release/ioquake3.wasm"
PREF_JSON="$BUILD_DIR/Release/ioquake3-config.json"

JS_FILE=""; WASM_FILE=""; DATA_FILE="";
if [ -f "$PREF_JS" ]; then JS_FILE="$PREF_JS"; else JS_FILE=$(rg --files -g "**/*.js" "$IOQ3_DIR" | rg -m1 "ioquake3|quake3|index"); fi
if [ -f "$PREF_WASM" ]; then WASM_FILE="$PREF_WASM"; else WASM_FILE=$(rg --files -g "**/*.wasm" "$IOQ3_DIR" | rg -m1 "ioquake3|quake3|index"); fi
DATA_FILE=$(rg --files -g "**/*.data" "$IOQ3_DIR" | rg -m1 "ioquake3|quake3|index" || true)

if [ -z "$JS_FILE" ] || [ -z "$WASM_FILE" ]; then
    echo "Could not locate required artifacts (.js/.wasm)"
    exit 1
fi

cp "$JS_FILE" "$FORGE_STATIC_DIR/index.js"
cp "$WASM_FILE" "$FORGE_STATIC_DIR/index.wasm"
if [ -n "$DATA_FILE" ]; then cp "$DATA_FILE" "$FORGE_STATIC_DIR/index.data"; else echo "[WARN] no .data file produced"; fi

# Also copy with original filenames expected by the glue
JS_BASE=$(basename "$JS_FILE"); WASM_BASE=$(basename "$WASM_FILE")
cp "$JS_FILE" "$FORGE_STATIC_DIR/$JS_BASE"
cp "$WASM_FILE" "$FORGE_STATIC_DIR/$WASM_BASE"
if [ -n "$DATA_FILE" ]; then DATA_BASE=$(basename "$DATA_FILE"); cp "$DATA_FILE" "$FORGE_STATIC_DIR/$DATA_BASE"; fi

# Copy config and game dirs if present
if [ -f "$PREF_JSON" ]; then cp "$PREF_JSON" "$FORGE_STATIC_DIR/ioquake3-config.json"; fi
for dir in baseq3 missionpack demoq3 tademo; do
  if [ -d "$BUILD_DIR/Release/$dir" ]; then
    mkdir -p "$FORGE_STATIC_DIR/$dir"
    rsync -a --delete "$BUILD_DIR/Release/$dir/" "$FORGE_STATIC_DIR/$dir/" 2>/dev/null || cp -R "$BUILD_DIR/Release/$dir/." "$FORGE_STATIC_DIR/$dir/"
  fi
done

# Verify files were copied
if [ -f "$FORGE_STATIC_DIR/index.js" ] && \
   [ -f "$FORGE_STATIC_DIR/index.wasm" ]; then
    echo "Build files successfully copied!"
else
    echo "Failed to copy some build files"
    exit 1
fi

# Show file sizes
echo "Build file sizes:"
ls -lh "$FORGE_STATIC_DIR/index.js" | awk '{print "  index.js:   " $5}'
ls -lh "$FORGE_STATIC_DIR/index.wasm" | awk '{print "  index.wasm: " $5}'
if [ -f "$FORGE_STATIC_DIR/index.data" ]; then ls -lh "$FORGE_STATIC_DIR/index.data" | awk '{print "  index.data: " $5}'; else echo "  index.data: (none)"; fi

# Compress files (optional)
if command -v gzip &> /dev/null; then
    echo "Compressing files with gzip..."
    gzip -9 -k "$FORGE_STATIC_DIR/index.wasm"
    if [ -f "$FORGE_STATIC_DIR/index.data" ]; then gzip -9 -k "$FORGE_STATIC_DIR/index.data"; fi
    gzip -9 -k "$FORGE_STATIC_DIR/$WASM_BASE"
    if [ -n "$DATA_FILE" ]; then gzip -9 -k "$FORGE_STATIC_DIR/$DATA_BASE"; fi
    echo "Compressed files created (.gz)"
fi
