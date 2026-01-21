# DOOM Forge App - Release Notes

## Version 1.0.0

**Release Date:** January 2026

### Overview

DOOM Forge App brings the classic 1993 first-person shooter to Atlassian Jira and Confluence. This release features full audio support including both sound effects and MIDI music, powered by the Dwasm (PrBoom+/PrBoomX) WebAssembly port.

---

### Features

#### Gameplay
- Authentic DOOM gameplay via PrBoom+/PrBoomX engine
- WebAssembly-powered native performance
- Includes shareware Episode 1 (Knee-Deep in the Dead)
- Classic DOOM controls with keyboard and mouse support

#### Audio (New)
- Full sound effects via SDL2 audio
- MIDI music playback via OPL2 synthesizer (Sound Blaster emulation)
- Proper Web Audio API integration for browser compatibility
- Audio unlock on user interaction (required by modern browsers)

#### Atlassian Integration
- Available as a Global Page in both Jira and Confluence
- Optional Issue Glance panel for quick access in Jira
- Runs entirely client-side within Forge Custom UI

---

### Technical Details

#### Engine
- **Base**: Dwasm (PrBoom+/PrBoomX WebAssembly port)
- **Source**: [GMH-Code/Dwasm](https://github.com/GMH-Code/Dwasm)
- **Compiler**: Emscripten 4.x
- **Runtime**: WebAssembly with SDL2

#### Audio Implementation
- Sound effects: SDL2 audio callback system
- Music: OPL2/OPL3 synthesizer emulation for MIDI playback
- Browser support: Chrome, Firefox, Safari, Edge

#### File Sizes
| File | Size |
|------|------|
| index.js | ~100-150 KB |
| index.wasm | ~2-3 MB |
| index.data | ~5-6 MB |
| **Total** | ~8-10 MB |

---

### Build Requirements

- Node.js 20.x
- Emscripten 4.x
- CMake 3.x
- Git

```bash
# Build command
./build-doom.sh
```

---

### Known Limitations

1. **Mobile Support**: Game loads on mobile browsers but touch controls are not implemented
2. **WAD Files**: Only shareware DOOM 1 is included; full version requires manual WAD replacement
3. **Saves**: Game saves may not persist across sessions due to Forge sandbox restrictions

---

### Controls

| Key | Action |
|-----|--------|
| W / Up Arrow | Move Forward |
| S / Down Arrow | Move Backward |
| A | Strafe Left |
| D | Strafe Right |
| Left/Right Arrow | Turn |
| Ctrl | Fire |
| Space | Use / Open |
| 1-7 | Select Weapon |
| Esc | Menu |

---

### Deployment

```bash
# First time setup
forge login
forge register

# Deploy
forge deploy

# Install to site
forge install
```

---

### Credits

- **id Software** - Original DOOM (1993)
- **PrBoom+ Team** - Enhanced DOOM source port
- **GMH-Code** - Dwasm WebAssembly port
- **Emscripten Team** - C/C++ to WebAssembly compiler

---

### License

GPL-2.0 License

This project uses open source components under GPL-2.0 and includes the freely distributable DOOM shareware WAD.
