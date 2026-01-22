// ... existing code ...

### Supported Command-Line Arguments

- `-iwad <file>` - Specify IWAD file
- `-skill <1-5>` - Set difficulty level
- `-warp <episode> <map>` - Start at specific level
- `-nomusic` - Disable music
- `-nosound` - Disable sound effects

// <CHANGE> Added important note about music support
**IMPORTANT: Music Support**

By default, doomgeneric includes music support. To ensure music works properly:

1. **Do NOT use the `-nomusic` flag** when building or running
2. **Ensure user interaction** - Modern browsers require user interaction (click/keypress) before audio can play
3. **Check the build** - The Makefile.emscripten should compile with SDL_mixer support enabled
4. **Verify the WAD** - Ensure doom1.wad contains music lumps (it should by default)

If music still doesn't work after building:
- Check browser console for audio-related errors
- Verify that sound effects work (if they do, the audio system is initialized)
- Try clicking on the canvas or the "Enable Audio" button after the game loads
- Some browsers may block MIDI playback - check browser audio permissions

## Troubleshooting

// ... existing code ...

### Music Not Playing But Sound Effects Work

This is usually caused by:

1. **Browser audio context not initialized** - The HTML now includes an audio initialization button. Make sure to click it or click on the canvas after the game loads.

2. **MIDI support issues** - Some browsers have limited MIDI support. The Emscripten build should use SDL_mixer which converts MIDI to audio.

3. **Build configuration** - Verify that the Makefile.emscripten includes:
   ```makefile
   USE_SDL_MIXER=1
   ```

4. **WAD file music data** - Verify doom1.wad contains music lumps:
   ```bash
   strings doom1.wad | grep -i "d_e1m1"
   ```
   If this returns nothing, your WAD might be missing music data.

### Build Error: "cannot detect undeclared builtins"

// ... existing code ...
```

```shellscript file="build-doom.sh"
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

# <CHANGE> Added check for music data in WAD file
echo ""
echo "Checking for music data in doom1.wad..."
if strings doom1.wad | grep -q "D_E1M1"; then
    echo "✓ Music lumps found in doom1.wad"
else
    echo "⚠ Warning: Music lumps might be missing from doom1.wad"
    echo "  The game will still work, but music may not play"
fi

# Build with Emscripten
echo ""
echo "Building DOOM WebAssembly files with music support..."
echo "This may take a few minutes..."
echo ""

# <CHANGE> Ensure music support is enabled (not using -nomusic flag)
echo "Note: Building with full audio support (music and sound effects)"

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
echo "IMPORTANT - Music Support:"
echo "  • Make sure to click the 'Enable Audio' button when the game loads"
echo "  • Modern browsers require user interaction to play audio"
echo "  • If music doesn't play, check browser console for errors"
echo ""
echo "Next steps:"
echo "  1. Test locally:  forge tunnel"
echo "  2. Deploy:        forge deploy"
echo "  3. Install:       forge install"
echo ""
