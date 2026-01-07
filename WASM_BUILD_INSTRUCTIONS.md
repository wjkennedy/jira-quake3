// ... existing code ...

# Building Doom WebAssembly Files

// <CHANGE> Switching from Chocolate Doom to doomgeneric which has better Emscripten 4.x support
This guide explains how to compile the Doom WebAssembly files using doomgeneric, which has excellent Emscripten support and a simpler build process.

## Why doomgeneric?

doomgeneric is specifically designed to be easily portable and has a well-maintained Emscripten port that works with modern Emscripten versions (4.x). It includes sound and music support out of the box.

## Prerequisites

### macOS
```bash
brew install emscripten
```

### Linux (Ubuntu/Debian)
```bash
# Install Emscripten
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

### Windows
1. Install WSL2 (Windows Subsystem for Linux)
2. Follow Linux instructions above

## Building

1. **Clone the doomgeneric repository:**
   ```bash
   git clone https://github.com/ozkl/doomgeneric.git
   cd doomgeneric/doomgeneric
   ```

2. **Build the Emscripten port:**
   ```bash
   make -f Makefile.emscripten
   ```

   That's it! The build is much simpler than Chocolate Doom.

3. **Locate the output files:**
   After successful build, you'll find these files in `doomgeneric/doomgeneric/`:
   - `doomgeneric.js`
   - `doomgeneric.wasm`
   - `doomgeneric.data` (packaged assets)

## Getting the Shareware WAD

1. **Download doom1.wad:**
   ```bash
   cd doomgeneric/doomgeneric
   wget https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad
   ```

   Or from other sources:
   - https://archive.org/details/DoomsharewareEpisode (search for "doom shareware")
   - Direct link: `wget http://www.doomworld.com/3ddownloads/ports/shareware_doom_iwad.zip`

2. **The Makefile will automatically package the WAD:**
   When you run `make -f Makefile.emscripten`, it will package doom1.wad into the .data file if it's present in the directory.

## Copying Files to Forge App

1. **Copy the compiled files:**
   ```bash
   # From the doomgeneric/doomgeneric directory
   cp doomgeneric.js /path/to/your/forge-app/static/doom/doom-wasm.js
   cp doomgeneric.wasm /path/to/your/forge-app/static/doom/
   cp doomgeneric.data /path/to/your/forge-app/static/doom/
   ```

   Note: We're renaming `doomgeneric.js` to `doom-wasm.js` to match our HTML file.

2. **Verify file structure:**
   ```
   static/doom/
   ├── index.html
   ├── doom-wasm.js
   ├── doomgeneric.wasm
   └── doomgeneric.data
   ```

## Quick Setup Script

Save this as `build-doom.sh` in your Forge app root:

```bash
#!/bin/bash

# Clone and build doomgeneric
if [ ! -d "doomgeneric" ]; then
    git clone https://github.com/ozkl/doomgeneric.git
fi

cd doomgeneric/doomgeneric

# Download doom1.wad if not present
if [ ! -f "doom1.wad" ]; then
    echo "Downloading doom1.wad..."
    wget https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad
fi

# Build with Emscripten
echo "Building Doom WebAssembly..."
make -f Makefile.emscripten

# Copy files to Forge app
echo "Copying files to Forge app..."
cp doomgeneric.js ../../static/doom/doom-wasm.js
cp doomgeneric.wasm ../../static/doom/
cp doomgeneric.data ../../static/doom/

echo "Done! Doom is ready to deploy."
```

Make it executable and run:
```bash
chmod +x build-doom.sh
./build-doom.sh
```

## Alternative: Use Pre-built Demo Files

You can download the working files from the live demo:

1. **Visit:** https://ozkl.github.io/doomgeneric/

2. **Open DevTools** (F12) → Network tab → Refresh

3. **Download these files:**
   - `doomgeneric.js` → rename to `doom-wasm.js`
   - `doomgeneric.wasm`
   - `doomgeneric.data`

4. **Copy to your Forge app's** `static/doom/` directory

## Customization

### Changing Game Settings

Modify the Module configuration in `index.html`:

```javascript
var Module = {
    arguments: ['-iwad', 'doom1.wad', '-window'],
    // ... rest of config
};
```

### Supported Command-Line Arguments

- `-iwad <file>` - Specify IWAD file
- `-skill <1-5>` - Set difficulty level
- `-warp <episode> <map>` - Start at specific level
- `-nomusic` - Disable music
- `-nosound` - Disable sound effects

## Troubleshooting

### Build Error: "cannot detect undeclared builtins"

This error occurs with Chocolate Doom's older autoconf scripts. That's why we switched to doomgeneric, which uses a simple Makefile and doesn't have this issue.

### Emscripten Version Check

```bash
emcc --version
# Should show 4.0.22 or similar
```

### Make Command Not Found

```bash
# macOS
brew install make

# Linux
sudo apt-get install build-essential
```

### Files Don't Load in Browser

- Check that files are in `static/doom/` directory
- Verify the script src in `index.html` matches the filename
- Check browser console for specific errors

## File Sizes

The doomgeneric build produces reasonable file sizes:

- doom-wasm.js: ~50-100 KB (loader script)
- doomgeneric.wasm: ~1.2 MB (game engine)
- doomgeneric.data: ~4.3 MB (includes doom1.wad and assets)
- **Total: ~5.5 MB**

This fits comfortably within Forge's static resource limits.

## Testing Locally

Before deploying to Forge:

```bash
# Start local server in static/doom directory
cd static/doom
python3 -m http.server 8000

# Open browser to http://localhost:8000
```

## Next Steps

After building and copying the files:

1. **Test locally:** `forge tunnel`
2. **Deploy:** `forge deploy`
3. **Install to Jira/Confluence:** `forge install`

## Resources

- [doomgeneric GitHub](https://github.com/ozkl/doomgeneric) - The source repository
- [Live Demo](https://ozkl.github.io/doomgeneric/) - Working example
- [Emscripten Documentation](https://emscripten.org/docs/getting_started/index.html)
- [DOOM Wiki](https://doomwiki.org/) - Game information and resources
```

```html file="" isHidden
