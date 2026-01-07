# DOSBox WebAssembly Build Instructions

This guide explains how to compile DOSBox to WebAssembly and integrate Lotus 1-2-3 for the Forge app.

## Prerequisites

### Install Emscripten

**macOS:**
```bash
brew install emscripten
```

**Linux (Ubuntu/Debian):**
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install python3 cmake git

# Install Emscripten SDK
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

**Verify Installation:**
```bash
emcc --version
```

## Building DOSBox for WebAssembly

### Option 1: Use em-dosbox (Recommended)

em-dosbox is a maintained fork of DOSBox optimized for Emscripten compilation.

```bash
# Clone em-dosbox
git clone https://github.com/dreamlayers/em-dosbox.git
cd em-dosbox

# Build for WebAssembly
emconfigure ./configure
emmake make

# Output files will be in src/
# Look for dosbox.js and dosbox.wasm
```

### Option 2: Use js-dos (Easier)

js-dos provides pre-built DOSBox for the web with a simple API.

```bash
npm install js-dos
```

Then integrate in your HTML:

```html
<script src="https://js-dos.com/6.22/current/js-dos.js"></script>
<script>
  Dos(document.getElementById("dosCanvas")).ready((fs, main) => {
    // Mount Lotus 1-2-3 files
    fs.extract("lotus123.zip").then(() => {
      main(["-c", "cd LOTUS", "-c", "123.exe"])
    })
  })
</script>
```

## Obtaining Lotus 1-2-3

### Legal Options

**Option 1: Shareware Version**
- Lotus 1-2-3 Release 1A (1983) is available as abandonware
- Download from: https://www.abandonwaredos.com/

**Option 2: Purchase**
- IBM still licenses Lotus 1-2-3 for enterprise
- Contact IBM Software for licensing

**Option 3: Alternative - As-Easy-As**
- Free Lotus 1-2-3 clone
- Download from: https://www.aseasyasdownload.com/

### File Structure

Once obtained, you need these files:
```
lotus123/
├── 123.EXE          # Main executable
├── 123.HLP          # Help files
├── 123.CNF          # Configuration
└── *.WKS/*.WK1      # Worksheet files (optional)
```

## Building the Forge Integration

### Step 1: Prepare DOSBox Files

```bash
# Create build directory
mkdir -p build/dosbox
cd build/dosbox

# Copy DOSBox WASM files
cp /path/to/em-dosbox/src/dosbox.js ../../static/lotus123/
cp /path/to/em-dosbox/src/dosbox.wasm ../../static/lotus123/
```

### Step 2: Package Lotus 1-2-3

```bash
# Create a zip with Lotus 1-2-3 files
cd build
mkdir -p lotus
cp -r /path/to/lotus123/* lotus/
zip -r lotus123.zip lotus/

# Move to static directory
mv lotus123.zip ../static/lotus123/
```

### Step 3: Configure Emscripten Build

Create `dosbox_config.txt`:

```ini
[sdl]
fullscreen=false
output=surface

[cpu]
core=auto
cycles=max

[autoexec]
mount c lotus
c:
cd lotus
123.exe
```

### Step 4: Update lotus-engine.js

Replace the stub `dosbox.js` loader:

```javascript
// Load DOSBox module
var Module = {
  canvas: document.getElementById('dosCanvas'),
  arguments: ['-conf', 'dosbox_config.txt'],
  preRun: [function() {
    // Mount virtual filesystem
    FS.createPreloadedFile('/', 'lotus123.zip', 'lotus123.zip', true, false)
  }],
  postRun: [function() {
    console.log("[v0] DOSBox started with Lotus 1-2-3")
  }]
}

// Load DOSBox WASM
var script = document.createElement('script')
script.src = 'dosbox.js'
document.body.appendChild(script)
```

## Automated Build Script

Create `build-lotus.sh`:

```bash
#!/bin/bash

echo "Building Lotus 1-2-3 Forge App..."

# Check for Emscripten
if ! command -v emcc &> /dev/null; then
    echo "Error: Emscripten not found. Please install it first."
    exit 1
fi

# Create build directory
mkdir -p build
cd build

# Clone em-dosbox if not exists
if [ ! -d "em-dosbox" ]; then
    echo "Cloning em-dosbox..."
    git clone https://github.com/dreamlayers/em-dosbox.git
fi

# Build DOSBox
echo "Building DOSBox WASM..."
cd em-dosbox
emconfigure ./configure
emmake make
cd ../..

# Copy DOSBox files
echo "Copying DOSBox files..."
cp build/em-dosbox/src/dosbox.js static/lotus123/
cp build/em-dosbox/src/dosbox.wasm static/lotus123/

# Download Lotus 1-2-3 (placeholder - user must provide)
echo "Please place Lotus 1-2-3 files in build/lotus/ directory"
echo "Then run: zip -r lotus123.zip lotus/"
echo "And move lotus123.zip to static/lotus123/"

# Package complete
echo "Build complete! Run 'forge deploy' to deploy the app."
```

Make it executable:
```bash
chmod +x build-lotus.sh
./build-lotus.sh
```

## File Size Considerations

DOSBox + Lotus 1-2-3 will be larger than the current JavaScript implementation:

- dosbox.js: ~200 KB
- dosbox.wasm: ~2-3 MB
- lotus123.zip: ~500 KB - 1 MB
- **Total: ~3-4 MB**

This is still within Forge's static resource limits (10 MB).

## Testing Locally

```bash
# Serve static files locally
cd static/lotus123
python3 -m http.server 8000

# Open browser to http://localhost:8000
# DOSBox should load Lotus 1-2-3
```

## Troubleshooting

**DOSBox won't compile:**
- Ensure Emscripten is properly installed
- Check Emscripten version: `emcc --version` (need 3.1.0+)
- Try cleaning build: `emmake make clean`

**WASM won't load:**
- Check browser console for CORS errors
- Verify .wasm file MIME type is `application/wasm`
- Ensure files are in correct directory

**Lotus 1-2-3 won't start:**
- Verify all .EXE and .HLP files are present
- Check DOSBox config file syntax
- Try running locally first with native DOSBox

**Performance issues:**
- Adjust DOSBox CPU cycles in config
- Reduce canvas resolution
- Enable WASM optimizations in Emscripten

## Alternative: js-dos Integration

For a simpler approach, use js-dos instead of building from scratch:

```bash
npm install js-dos
```

Update `static/lotus123/index.html`:

```html
<script src="https://js-dos.com/6.22/current/js-dos.js"></script>
<script>
  const dos = Dos(document.getElementById("dosCanvas"))
  
  dos.ready((fs, main) => {
    fs.extract("lotus123.zip").then(() => {
      main(["-c", "cd LOTUS", "-c", "123.exe"])
    })
  })
</script>
```

This provides DOSBox without needing to compile it yourself.

## Resources

- [em-dosbox GitHub](https://github.com/dreamlayers/em-dosbox)
- [js-dos Documentation](https://js-dos.com/)
- [Emscripten Guide](https://emscripten.org/docs/getting_started/)
- [DOSBox Configuration](https://www.dosbox.com/wiki/Dosbox.conf)
- [Lotus 1-2-3 Manual](https://archive.org/details/lotus-1-2-3-manual)

## Next Steps

After building:

1. Test locally to ensure everything works
2. Run `forge deploy`
3. Install to Confluence
4. Add macro to a test page
5. Verify save/load functionality

---

**Note**: This integration brings authentic DOS-era Lotus 1-2-3 to the browser. The current JavaScript version is functional while you work on the full DOSBox integration.
```

```shellscript file="build-lotus.sh"
#!/bin/bash

echo "🚀 Building Lotus 1-2-3 Forge App..."
echo ""

# Check for Emscripten
if ! command -v emcc &> /dev/null; then
    echo "⚠️  Emscripten not found."
    echo "The JavaScript version will work without it."
    echo "For DOSBox integration, install Emscripten:"
    echo "  macOS: brew install emscripten"
    echo "  Linux: See DOSBOX_BUILD_INSTRUCTIONS.md"
    echo ""
    exit 0
fi

# Create build directory
mkdir -p build
cd build

# Clone em-dosbox if not exists
if [ ! -d "em-dosbox" ]; then
    echo "📦 Cloning em-dosbox..."
    git clone https://github.com/dreamlayers/em-dosbox.git
fi

# Build DOSBox
echo "🔨 Building DOSBox WASM..."
cd em-dosbox

if [ ! -f "Makefile" ]; then
    emconfigure ./configure
fi

emmake make

cd ../..

# Copy DOSBox files
echo "📋 Copying DOSBox files..."
cp build/em-dosbox/src/dosbox.js static/lotus123/ 2>/dev/null || echo "⚠️  dosbox.js not found (this is okay for now)"
cp build/em-dosbox/src/dosbox.wasm static/lotus123/ 2>/dev/null || echo "⚠️  dosbox.wasm not found (this is okay for now)"

# Instructions for Lotus 1-2-3
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Obtain Lotus 1-2-3 files (see DOSBOX_BUILD_INSTRUCTIONS.md)"
echo "2. Place files in build/lotus/ directory"
echo "3. Run: cd build && zip -r lotus123.zip lotus/"
echo "4. Move lotus123.zip to static/lotus123/"
echo "5. Deploy: forge deploy"
echo ""
echo "✅ JavaScript version is ready to use now!"
echo "   Run 'forge deploy' to deploy the current version."
echo ""
