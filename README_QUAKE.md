# Quake for Jira - Qwasm Integration

This project brings the classic Quake game into Atlassian Jira and Confluence using Qwasm (Quake WebAssembly).

## Features

- **Play Quake in your browser** - Run the iconic 1996 FPS directly in Jira or Confluence
- **Software & WebGL rendering** - Choose between authentic software rendering or faster WebGL acceleration
- **Mission Pack Support** - Compatible with Scourge of Armagon and Dissolution of Eternity
- **Mods & Custom Content** - Supports QuakeC mods, custom maps, and additional PAK files
- **Browser-based saves** - Your game progress persists in browser storage
- **Full controls** - Keyboard and mouse support with customizable key mapping

## Quick Start

### 1. Prerequisites

- Node.js and npm installed
- Forge CLI: `npm install -g @forge/cli`
- Atlassian account with Jira or Confluence access
- Quake PAK files (see below)

### 2. Obtaining Quake Files

You need Quake game data files (PAK files) to play:

**Shareware Version (Free):**
- Download Quake 1.06 shareware (`quake106.zip`)
- Extract `PAK0.PAK` from the `ID1` folder
- Rename to lowercase: `pak0.pak`

**Full Version (Commercial):**
- Purchase Quake from Steam, GOG, or other retailers
- Copy both `pak0.pak` and `pak1.pak`

See `QWASM_BUILD_INSTRUCTIONS.md` for detailed instructions.

### 3. Building Qwasm

```bash
# Make the build script executable
chmod +x build-quake.sh

# Run the build script (requires Emscripten)
./build-quake.sh software

# Or for WebGL version (faster):
export GL4ES_PATH=/path/to/gl4es
./build-quake.sh webgl
```

See `QWASM_BUILD_INSTRUCTIONS.md` for manual build instructions.

### 4. Deploy to Forge

```bash
# Log in to Forge
forge login

# Deploy the app
forge deploy

# Install to your site
forge install
```

## Project Structure

```
.
├── manifest.yml                 # Forge app manifest (includes Quake modules)
├── src/
│   └── index.js                # Resolver for both DOOM and Quake
├── static/
│   ├── doom/                   # DOOM game files
│   │   ├── index.html
│   │   ├── styles.css
│   │   ├── doom-logo.png
│   │   └── [DOOM WebAssembly files]
│   └── quake/                  # Quake game files
│       ├── index.html          # Quake game interface
│       ├── styles.css          # Quake-specific styling
│       ├── quake-logo.png      # Quake logo (optional)
│       ├── index.js            # Qwasm JavaScript (from build)
│       ├── index.wasm          # Qwasm WebAssembly (from build)
│       └── index.data          # Quake game data (from build)
├── build-quake.sh              # Automated build script
├── QWASM_BUILD_INSTRUCTIONS.md # Detailed build guide
└── README_QUAKE.md             # This file
```

## How It Works

1. **Qwasm Engine**: A WebAssembly port of the Quake engine that runs in the browser
2. **PAK Files**: Game data (maps, textures, sounds) packaged during build
3. **Emscripten**: Compiles the C code to WebAssembly
4. **Forge Integration**: Serves Quake as a custom UI module in Jira/Confluence

## Controls

| Key | Action |
|-----|--------|
| W / ↑ | Move Forward |
| S / ↓ | Move Backward |
| A | Strafe Left |
| D | Strafe Right |
| ← / → | Turn Left/Right |
| Ctrl | Fire |
| Space | Jump |
| 1-8 | Select Weapon |
| ESC | Menu |
| ~ | Console |

## Configuration

### URL Parameters

Pass Quake command-line arguments via URL:

```
https://your-forge-app/?-winsize&1152&864&+map&e1m1
```

**Common Parameters:**
- `-winsize <w> <h>` - Set resolution
- `+map <name>` - Start specific map
- `+skill <0-3>` - Set difficulty
- `-hipnotic` - Mission Pack 1
- `-rogue` - Mission Pack 2

### Mission Packs

To use mission packs:
1. Rename mission pack PAK as `pak2.pak`
2. Add to `id1` folder before building
3. Use `-hipnotic` or `-rogue` parameter

## Performance

Qwasm performs exceptionally well in browsers:

- **95-105x faster** than DOSBox WebAssembly
- **3x faster** than native DOSBox on x86
- **WebGL 2-3.5x faster** than software rendering
- **60+ FPS** on most modern hardware

## Troubleshooting

### Game Won't Load

- Verify all three files exist: `index.js`, `index.wasm`, `index.data`
- Check browser console for errors
- Ensure PAK files were included in build
- Clear browser cache and reload

### No Audio

- Click anywhere in the game window
- Check browser console for audio errors
- Ensure `unsafe-eval` is enabled in `manifest.yml`

### Poor Performance

- Use WebGL build instead of software rendering
- Lower resolution with `-winsize` parameter
- Enable hardware acceleration in browser
- Close other tabs/applications

### Build Errors

- Ensure Emscripten is properly installed and activated
- Verify PAK files are lowercase and in correct location
- Check that all build dependencies are installed
- See `QWASM_BUILD_INSTRUCTIONS.md` for details

## License & Legal

**Important:**

- **Qwasm engine code**: Open source (check repository for license)
- **Quake game data**: Proprietary - owned by id Software/Bethesda
- **Shareware PAK**: May only be distributed as original archive
- **Commercial PAK**: Cannot be redistributed - users must own a copy

**Do NOT:**
- Host PAK files publicly
- Distribute Quake game data
- Use for commercial purposes without proper licensing

**This project is not affiliated with id Software, Bethesda, or ZeniMax Media.**

## Resources

- [Qwasm GitHub](https://github.com/GMH-Code/Qwasm) - Original Qwasm project
- [DOOM Forge App](static/doom) - Similar project for DOOM
- [Emscripten Docs](https://emscripten.org/) - WebAssembly compiler
- [Forge Platform](https://developer.atlassian.com/platform/forge/) - Atlassian Forge docs

## Contributing

To add features or fix bugs:

1. Fork this repository
2. Make your changes
3. Test thoroughly in Forge environment
4. Submit a pull request

## Support

For issues with:
- **Qwasm engine**: See [Qwasm repository](https://github.com/GMH-Code/Qwasm/issues)
- **Forge integration**: Check Atlassian Forge documentation
- **This app**: Open an issue in this repository

## Acknowledgments

- **GMH-Code** - Creator of Qwasm
- **id Software** - Original Quake game
- **Emscripten team** - WebAssembly toolchain
- **Atlassian** - Forge platform

---

**Have fun fragging in Jira!** 🎮
