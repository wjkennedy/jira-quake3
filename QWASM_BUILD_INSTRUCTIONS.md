# Qwasm Build Instructions for Jira Forge App

This guide explains how to build Qwasm (Quake WebAssembly) and integrate it into your Jira Forge app.

## Prerequisites

1. Linux environment (or WSL on Windows)
2. Emscripten SDK installed
3. Quake PAK files (see below for details)
4. git, make, and standard build tools

## Getting Quake PAK Files

### Shareware Version (Free)

1. Download **Quake 1.06 shareware** (`quake106.zip`)
2. Extract `resource.1` using 7-Zip, WinRAR, or similar
3. Find `PAK0.PAK` in the `ID1` folder
4. Rename to lowercase: `pak0.pak`

**SHA256 Checksum for PAK0.PAK:**
```
35A9C55E5E5A284A159AD2A62E0E8DEF23D829561FE2F54EB402DBC0A9A946AF
```

### Full Version (Commercial)

If you own the full version of Quake:
1. You'll also have `PAK1.PAK` 
2. Rename to lowercase: `pak1.pak`
3. Both files should be in the `id1` folder

**SHA256 Checksum for PAK1.PAK:**
```
94E355836EC42BC464E4CBE794CFB7B5163C6EFA1BCC575622BB36475BF1CF30
```

## Building Qwasm

### 1. Clone the Qwasm Repository

```bash
git clone https://github.com/GMH-Code/Qwasm.git
cd Qwasm
```

### 2. Setup Emscripten

```bash
cd /path/to/emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

### 3. Add PAK Files

```bash
# Create the id1 directory if it doesn't exist
mkdir -p WinQuake/id1

# Copy your PAK files (must be lowercase)
cp /path/to/pak0.pak WinQuake/id1/
# Optional: Add pak1.pak for full version
# cp /path/to/pak1.pak WinQuake/id1/
```

### 4. Build Software-Rendered Qwasm

```bash
cd WinQuake
make -f Makefile.emscripten
```

This will generate:
- `index.html`
- `index.js`
- `index.wasm`
- `index.data`

### 5. Build Hardware-Rendered Qwasm (WebGL)

For better performance with WebGL:

```bash
# First, build GL4ES for Emscripten
cd /tmp
git clone https://github.com/ptitSeb/gl4es.git
cd gl4es
mkdir build
cd build
emcmake cmake .. -DNOX11=ON -DNOEGL=ON
emmake make

# Then build Qwasm with GL4ES
cd /path/to/Qwasm/WinQuake
make -f Makefile.emscripten GL4ES_PATH=/tmp/gl4es
```

## Integrating with Forge App

### 1. Copy Build Output

After building, copy the generated files to your Forge app:

```bash
# From the Qwasm/WinQuake directory
cp index.js /path/to/forge-app/static/quake/
cp index.wasm /path/to/forge-app/static/quake/
cp index.data /path/to/forge-app/static/quake/
```

**Important:** Do NOT copy `index.html` - use the one provided in the Forge app instead.

### 2. Add Quake Logo (Optional)

Create or download a Quake logo and save it as:
```
/path/to/forge-app/static/quake/quake-logo.png
```

### 3. Verify File Structure

Your Forge app should have:
```
static/quake/
├── index.html (provided by Forge app)
├── styles.css (provided by Forge app)
├── index.js (from Qwasm build)
├── index.wasm (from Qwasm build)
├── index.data (from Qwasm build)
└── quake-logo.png (optional)
```

## Command-Line Arguments

You can pass Quake command-line arguments via URL parameters:

```
https://your-forge-app/?-winsize&1152&864&+map&e1m1
```

Common arguments:
- `-winsize <width> <height>` - Set canvas resolution
- `+map <mapname>` - Start a specific map
- `-hipnotic` - Enable Mission Pack 1 (Scourge of Armagon)
- `-rogue` - Enable Mission Pack 2 (Dissolution of Eternity)
- `+skill <0-3>` - Set difficulty (0=easy, 3=nightmare)

## Performance Optimization

### Compress Build Files

For faster loading, compress the WebAssembly files:

```bash
# Using gzip
gzip -9 -k index.wasm
gzip -9 -k index.data

# Or using brotli
brotli -9 -k index.wasm
brotli -9 -k index.data
```

Configure your web server to serve pre-compressed files.

### WebGL vs Software Rendering

- **WebGL** (GL4ES build): 2-3.5x faster, better for high resolutions
- **Software rendering**: More compatible, true to original look

## Troubleshooting

### Audio Not Working

- Click anywhere in the game window to unlock audio
- Check browser console for audio context errors
- Ensure `unsafe-eval` is enabled in `manifest.yml`

### PAK Files Not Loading

- Ensure PAK files are lowercase (`pak0.pak`, not `PAK0.PAK`)
- Verify checksums match the official files
- Check that files are in the `id1` folder during build

### Game Crashes or Won't Start

- Check browser console for errors
- Verify all three files exist: `index.js`, `index.wasm`, `index.data`
- Ensure WebAssembly is enabled in your browser
- Try clearing browser cache

### Performance Issues

- Use the WebGL build instead of software rendering
- Lower the canvas resolution with `-winsize` parameter
- Close other browser tabs
- Check browser's hardware acceleration settings

## License Notes

**Important:** 
- The Quake shareware version license only permits distribution of the original archive
- Do NOT host `pak0.pak` or `pak1.pak` publicly on servers
- Users must provide their own PAK files
- The Qwasm engine code is open source, but Quake game data is not

## Additional Resources

- [Qwasm GitHub Repository](https://github.com/GMH-Code/Qwasm)
- [Emscripten Documentation](https://emscripten.org/docs/getting_started/downloads.html)
- [GL4ES Repository](https://github.com/ptitSeb/gl4es)

## Deployment to Forge

After integrating the build files:

```bash
# Install Forge dependencies
forge deploy

# Follow the prompts to deploy to your Atlassian site
```

Your Quake game will now be available in both Jira and Confluence!
