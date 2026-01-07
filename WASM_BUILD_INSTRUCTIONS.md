# Building Chocolate Doom WebAssembly Files

This guide explains how to compile the Chocolate Doom WebAssembly files needed for the Forge app.

## Prerequisites

### macOS
```bash
brew install emscripten
brew install automake
brew install sdl2 sdl2_mixer sdl2_net
```

### Linux (Ubuntu/Debian)
```bash
# Install Emscripten
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh

# Install dependencies
sudo apt-get install automake
sudo apt-get install libsdl2-dev libsdl2-mixer-dev libsdl2-net-dev
```

### Windows
1. Install WSL2 (Windows Subsystem for Linux)
2. Follow Linux instructions above

## Building

1. **Clone the Chocolate Doom WASM repository:**
   ```bash
   git clone https://github.com/cloudflare/doom-wasm.git
   cd doom-wasm
   ```

2. **Clean previous builds:**
   ```bash
   ./scripts/clean.sh
   ```

3. **Build the WebAssembly files:**
   ```bash
   ./scripts/build.sh
   ```

4. **Locate the output files:**
   After successful build, find these files in the `src/` directory:
   - `chocolate-doom.js`
   - `chocolate-doom.wasm`
   - `chocolate-doom.data` (if generated)

## Getting the Shareware WAD

1. **Download doom1.wad:**
   ```bash
   cd src
   wget https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad
   ```

   Or from other sources:
   - https://archive.org/details/DoomsharewareEpisode
   - https://doomwiki.org/wiki/DOOM1.WAD

2. **Verify the WAD file:**
   ```bash
   # doom1.wad should be approximately 4.2 MB
   ls -lh doom1.wad
   ```

## Copying Files to Forge App

1. **Copy the compiled files:**
   ```bash
   # From the doom-wasm/src directory
   cp chocolate-doom.js /path/to/forge-app/static/doom/
   cp chocolate-doom.wasm /path/to/forge-app/static/doom/
   cp doom1.wad /path/to/forge-app/static/doom/
   ```

2. **Verify file structure:**
   ```
   static/doom/
   ├── index.html
   ├── chocolate-doom.js
   ├── chocolate-doom.wasm
   └── doom1.wad
   ```

## Alternative: Pre-built Files

If you prefer not to build from source, you can use pre-built files:

1. **Visit the demo site:**
   https://silentspacemarine.com/

2. **Extract files from browser:**
   - Open browser DevTools (F12)
   - Go to Network tab
   - Refresh the page
   - Download:
     - `chocolate-doom.js`
     - `chocolate-doom.wasm`

3. **Download doom1.wad separately** (it's not loaded from the demo site)

## Customization

### Changing Game Settings

You can modify the Emscripten Module in `index.html` to pass command-line arguments to Doom:

```javascript
var Module = {
    arguments: ['-iwad', 'doom1.wad', '-window', '-nogui'],
    // ... rest of config
};
```

### Adding Music

To enable music, you need to add a timidity configuration:
1. Add `timidity.cfg` to the static/doom directory
2. Add soundfont files (.sf2)
3. Update the build script to include these files

## Troubleshooting

**Build fails:**
- Ensure Emscripten is properly installed: `emcc --version`
- Check that all dependencies are installed
- Try cleaning and rebuilding: `./scripts/clean.sh && ./scripts/build.sh`

**Large file sizes:**
- chocolate-doom.wasm is typically 1-2 MB
- doom1.wad is approximately 4.2 MB
- These are within Forge's limits

**WASM doesn't load:**
- Verify MIME types are correct
- Check browser console for errors
- Ensure files are in the correct directory

## File Size Considerations

Forge apps have size limits. The WASM implementation should fit comfortably:

- chocolate-doom.js: ~50-200 KB
- chocolate-doom.wasm: ~1-2 MB
- doom1.wad: ~4.2 MB
- Total: ~6.5 MB

This is within Forge's resource limits for static files.

## Next Steps

After building and copying the files:

1. Test locally: `forge tunnel`
2. Deploy: `forge deploy`
3. Install: `forge install`

## Resources

- [Cloudflare doom-wasm GitHub](https://github.com/cloudflare/doom-wasm)
- [Emscripten Documentation](https://emscripten.org/docs/getting_started/index.html)
- [Chocolate Doom](https://www.chocolate-doom.org/)
- [DOOM Wiki](https://doomwiki.org/)
```

```js file="static/doom/doom-engine.js" isDeleted="true"
...deleted...
