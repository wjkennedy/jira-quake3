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

echo "Checking for disk extraction tools..."
EXTRACT_TOOL=""
if command -v 7z &> /dev/null; then
    EXTRACT_TOOL="7z"
    echo "✓ 7z found for disk image extraction"
elif command -v mtools &> /dev/null; then
    EXTRACT_TOOL="mtools"
    echo "✓ mtools found for disk image extraction"
else
    echo "Error: No disk extraction tool found"
    echo ""
    echo "Please install one of the following:"
    echo "  macOS: brew install p7zip  (or)  brew install mtools"
    echo "  Linux: apt install p7zip-full  (or)  apt install mtools"
    exit 1
fi
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

if [ ! -d "lotus" ] || [ ! -f "lotus/123.EXE" ]; then
    echo ""
    echo "Downloading Lotus 1-2-3..."
    echo ""
    echo "NOTE: Lotus 1-2-3 is commercial software. You need a legal copy."
    echo "Available sources:"
    echo "  - WinWorld: https://winworldpc.com/product/lotus-1-2-3/2x"
    echo "  - Archive.org: https://archive.org/details/software"
    echo ""
    
    # Try WinWorld first (Release 2.4)
    echo "Attempting to download from WinWorld..."
    
    if wget -q --user-agent="Mozilla/5.0" -O lotus_disks.zip "https://winworldpc.com/download/c38ec38d-8618-c39a-11c3-a4e284a2c3a5"; then
        echo "✓ Lotus 1-2-3 disk images downloaded"
        
        mkdir -p lotus_temp
        unzip -q lotus_disks.zip -d lotus_temp
        echo "✓ Archive extracted"
        
        # Extract files from disk images
        echo ""
        echo "Extracting files from disk images..."
        mkdir -p lotus
        
        if [ "$EXTRACT_TOOL" = "7z" ]; then
            # Find all .img or .ima files and extract
            find lotus_temp -type f -iname "*.img" -o -iname "*.ima" | while read imgfile; do
                echo "  Extracting: $(basename "$imgfile")"
                7z x -y -o"lotus" "$imgfile" >/dev/null 2>&1 || true
            done
        elif [ "$EXTRACT_TOOL" = "mtools" ]; then
            # Use mtools to copy files from disk images
            find lotus_temp -type f -iname "*.img" -o -iname "*.ima" | while read imgfile; do
                echo "  Extracting: $(basename "$imgfile")"
                # Create temporary mtools config
                echo "drive c: file=\"$imgfile\"" > mtoolsrc_temp
                MTOOLSRC=mtoolsrc_temp mcopy -s -n c:/* lotus/ 2>/dev/null || true
            done
            rm -f mtoolsrc_temp
        fi
        
        # Clean up temp directory
        rm -rf lotus_temp
        
        echo "✓ Files extracted from disk images"
    else
        echo ""
        echo "Automatic download failed."
        echo ""
        echo "Please download Lotus 1-2-3 manually:"
        echo "  1. Visit: https://winworldpc.com/product/lotus-1-2-3/2x"
        echo "  2. Download Release 2.x or 3.x disk images"
        echo "  3. Extract disk images using:"
        echo "       7z x disk1.img -o./build/dosbox/lotus/"
        echo "       7z x disk2.img -o./build/dosbox/lotus/"
        echo ""
        echo "Expected structure:"
        echo "  build/dosbox/lotus/123.EXE"
        echo "  build/dosbox/lotus/*.HLP"
        echo "  build/dosbox/lotus/*.DRV"
        echo ""
        echo "Alternatively, if you have the disk images:"
        echo "  Place .img/.ima files in build/dosbox/ and re-run this script"
        
        # Check if user has placed disk images
        if ls *.img >/dev/null 2>&1 || ls *.ima >/dev/null 2>&1; then
            echo ""
            echo "Found disk image files, attempting extraction..."
            mkdir -p lotus
            
            if [ "$EXTRACT_TOOL" = "7z" ]; then
                for imgfile in *.img *.ima; do
                    [ -f "$imgfile" ] && 7z x -y -o"lotus" "$imgfile" >/dev/null 2>&1
                done
            fi
        else
            exit 1
        fi
    fi
else
    echo "✓ Lotus 1-2-3 files already exist"
fi

# Verify lotus files
if [ ! -d "lotus" ] || [ ! -f "lotus/123.EXE" ]; then
    echo ""
    echo "Error: Lotus 1-2-3 files not found"
    echo ""
    echo "Main executable (123.EXE) is missing."
    echo "Please extract disk images manually to build/dosbox/lotus/"
    echo ""
    echo "You can extract with:"
    echo "  7z x disk1.img -o./lotus/"
    echo "  7z x disk2.img -o./lotus/"
    echo ""
    ls -la lotus/ 2>/dev/null || echo "lotus directory not found"
    exit 1
fi

echo "✓ Lotus 1-2-3 files verified (123.EXE found)"

# Build DOSBox with Emscripten
echo ""
echo "Building DOSBox WebAssembly files..."
echo "This may take several minutes..."
echo ""

if [ ! -f "configure" ]; then
    echo "Generating configure script..."
    if [ -f "autogen.sh" ]; then
        ./autogen.sh
    elif [ -f "bootstrap" ]; then
        ./bootstrap
    else
        echo "Error: configure script not found and cannot be generated"
        echo "Please check the em-dosbox repository structure"
        ls -la
        exit 1
    fi
    echo "✓ Configure script generated"
fi

# Configure for Emscripten build
if [ ! -f "Makefile" ]; then
    emconfigure ./configure --disable-opengl --disable-sdl2-test
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
