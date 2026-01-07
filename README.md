# DOOM Forge App for Jira & Confluence

A Chocolate Doom WebAssembly port packaged as a Forge app for Atlassian Jira and Confluence. This is the actual DOOM game engine compiled to WebAssembly with shareware WAD file support.

## Features

- 🎮 Authentic DOOM gameplay via Chocolate Doom source port
- 🕹️ WebAssembly-powered performance
- 📦 Includes shareware Episode 1 (doom1.wad)
- 🎵 Full sound and music support
- ⌨️ Classic DOOM controls
- 🌐 Runs entirely in the browser

## Installation

### Prerequisites

1. Install the Forge CLI:
```bash
npm install -g @forge/cli
```

2. Log in to Forge:
```bash
forge login
```

### Build Required Files

**IMPORTANT**: Before deploying, you need to compile the Chocolate Doom WebAssembly files and obtain the shareware WAD.

See `WASM_BUILD_INSTRUCTIONS.md` for detailed build instructions.

Required files in `static/doom/`:
- `chocolate-doom.js` (Emscripten-generated JavaScript)
- `chocolate-doom.wasm` (Compiled WebAssembly binary)
- `doom1.wad` (Shareware game data - ~4.2 MB)

### Deploy the App

1. Navigate to the project directory

2. Register the app (first time only):
```bash
forge register
```

3. Update the `manifest.yml` with your app ID from the registration

4. Deploy the app:
```bash
forge deploy
```

5. Install the app to your Jira/Confluence site:
```bash
forge install
```

## Controls

- **↑ / W** - Move Forward
- **↓ / S** - Move Backward
- **← / →** - Turn Left/Right
- **A / D** - Strafe Left/Right
- **Ctrl** - Fire
- **Space** - Use/Open
- **1-7** - Select Weapon
- **ESC** - Menu

## How It Works

### Chocolate Doom

This app uses Chocolate Doom, a source port that accurately reproduces the original DOS version of DOOM. It's compiled to WebAssembly using Emscripten, allowing it to run natively in the browser.

### WebAssembly Integration

1. **Emscripten**: Compiles C/C++ DOOM source code to WASM
2. **Virtual File System**: Loads doom1.wad into Emscripten's virtual filesystem
3. **SDL2**: Provides graphics, input, and audio through browser APIs
4. **Canvas Rendering**: Game renders to HTML5 Canvas element

### Forge Integration

- **Custom UI Resources**: Static files hosted by Atlassian infrastructure
- **Global Pages**: Accessible from Jira and Confluence app menus
- **Issue Glance**: Optional DOOM launcher in Jira issues (because why not?)

## Accessing the Game

### In Jira

1. Click the "Apps" dropdown in the top navigation
2. Select "DOOM" from the menu
3. Or view the glance panel on any issue

### In Confluence

1. Click the "Apps" dropdown in the top navigation
2. Select "DOOM" from the menu

## Technical Stack

- **Forge Platform**: Atlassian's serverless app framework
- **Chocolate Doom**: Accurate DOOM source port
- **WebAssembly**: Native-speed game engine execution
- **Emscripten**: C to WASM compiler toolchain
- **SDL2**: Cross-platform multimedia library

## File Structure

```
forge-doom-app/
├── manifest.yml                    # Forge app configuration
├── package.json                    # Node dependencies
├── src/
│   └── index.js                   # Forge resolver function
├── static/doom/
│   ├── index.html                 # Game launcher page
│   ├── chocolate-doom.js          # Emscripten JS (BUILD REQUIRED)
│   ├── chocolate-doom.wasm        # WASM binary (BUILD REQUIRED)
│   └── doom1.wad                  # Shareware game data (DOWNLOAD REQUIRED)
└── WASM_BUILD_INSTRUCTIONS.md     # Build guide
```

## Building from Source

Detailed instructions in `WASM_BUILD_INSTRUCTIONS.md`:

1. Clone Cloudflare's doom-wasm repository
2. Install Emscripten SDK
3. Run build scripts
4. Copy output files to `static/doom/`
5. Download doom1.wad shareware file

### Quick Build (macOS/Linux)

```bash
# Install dependencies
brew install emscripten automake sdl2 sdl2_mixer sdl2_net

# Clone and build
git clone https://github.com/cloudflare/doom-wasm.git
cd doom-wasm
./scripts/clean.sh
./scripts/build.sh

# Copy files
cp src/chocolate-doom.js /path/to/forge-app/static/doom/
cp src/chocolate-doom.wasm /path/to/forge-app/static/doom/

# Download shareware WAD
cd /path/to/forge-app/static/doom/
wget https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad
```

## Development

### Local Testing

```bash
# Start local tunnel
forge tunnel

# Access at the provided URL
```

### Modifying the Game

The actual game logic is in the compiled WASM. To modify:

1. Edit source in the doom-wasm repository
2. Rebuild WASM files
3. Copy to static/doom/
4. Redeploy: `forge deploy`

### Customizing the UI

Edit `static/doom/index.html` to customize:
- Loading screens
- Control instructions
- Canvas styling
- Emscripten Module configuration

## File Size Considerations

Total app size: ~6.5 MB

- chocolate-doom.js: ~50-200 KB
- chocolate-doom.wasm: ~1-2 MB  
- doom1.wad: ~4.2 MB

This is within Forge's static resource limits.

## Performance

- Native WASM execution speed
- 35 FPS (original DOOM framerate)
- Resolution: 320x200 (scaled to canvas)
- Works on desktop and mobile browsers

## License

GPL-2.0 License

This project uses:
- Chocolate Doom source port (GPL-2.0)
- Original DOOM game engine by id Software
- Shareware episode freely available

## Credits

- **id Software**: Original DOOM (1993)
- **Chocolate Doom Team**: Accurate DOOM source port
- **Cloudflare**: WebAssembly port (doom-wasm)
- **Emscripten Team**: C/C++ to WebAssembly compiler

## Troubleshooting

**Files not loading:**
- Verify all three files exist in `static/doom/`
- Check browser console for errors
- Ensure WASM MIME type is correct

**Game won't start:**
- Click on canvas to give it focus
- Check that doom1.wad is the shareware version
- Verify WASM files compiled correctly

**Performance issues:**
- Close other browser tabs
- Try a different browser (Chrome/Firefox recommended)
- Check browser WebAssembly support

## Resources

- [Chocolate Doom](https://www.chocolate-doom.org/)
- [Cloudflare doom-wasm](https://github.com/cloudflare/doom-wasm)
- [Emscripten Documentation](https://emscripten.org/)
- [Forge Developer Guide](https://developer.atlassian.com/platform/forge/)
- [DOOM Wiki](https://doomwiki.org/)

---

**Note**: This is an authentic DOOM implementation using the original game engine compiled to WebAssembly, not a recreation. You're playing the real DOOM!
