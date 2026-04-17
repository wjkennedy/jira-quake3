#!/bin/bash

# ioquake3 (jioq3) Build Script for Forge App Integration
# This script builds ioquake3 with Emscripten and prepares it for the Forge app.

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

printf "%bioquake3 Build Script for Forge App%b\n" "${GREEN}" "${NC}"
echo "========================================"

# Configuration
IOQ3_REPO="${IOQ3_REPO:-https://github.com/wjkennedy/jioq3}"
IOQ3_DIR="./ioq3-build"
FORGE_STATIC_DIR="static/quake3"
ENGINE_DIR="$FORGE_STATIC_DIR/engine"
BUILD_DIR="$IOQ3_DIR/build/emscripten"

# Options
# Forge Custom UI resources are limited to 100 MB per resource. The Quake III
# demo pak fits comfortably, so the default build packages a playable demo into
# ioquake3.data. Full retail assets remain opt-in because pak0.pk3 ownership and
# distribution are outside this app.
INCLUDE_POINT_RELEASE=false
LEAN=false
DEMO=true
PRELOAD=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full|--include-point-release)
      INCLUDE_POINT_RELEASE=true; LEAN=false; DEMO=false; PRELOAD=0; shift ;;
    --lean|--pak0-only)
      INCLUDE_POINT_RELEASE=false; LEAN=true; DEMO=false; PRELOAD=0; shift ;;
    --demo)
      DEMO=true; INCLUDE_POINT_RELEASE=false; LEAN=false; PRELOAD=1; shift ;;
    --preload)
      PRELOAD=1; shift ;;
    *)
      print_warning "Unknown arg: $1"; shift ;;
  esac
done

# Function to print colored messages
print_info() {
    printf "%b[INFO]%b %s\n" "${GREEN}" "${NC}" "$1"
}

print_warning() {
    printf "%b[WARNING]%b %s\n" "${YELLOW}" "${NC}" "$1"
}

print_error() {
    printf "%b[ERROR]%b %s\n" "${RED}" "${NC}" "$1"
}

# Ensure Emscripten environment is active (emsdk)
prepare_emscripten() {
    # If emcc and emcmake already available, nothing to do
    if command -v emcc >/dev/null 2>&1 && command -v emcmake >/dev/null 2>&1; then
        return
    fi

    # Try common emsdk locations or EMSDK env var
    local candidates=()
    if [ -n "${EMSDK:-}" ]; then
        candidates+=("$EMSDK")
    fi
    candidates+=("$HOME/emsdk")

    for d in "${candidates[@]}"; do
        if [ -f "$d/emsdk_env.sh" ]; then
            print_info "Sourcing emsdk environment from $d"
            # shellcheck disable=SC1090
            . "$d/emsdk_env.sh" >/dev/null
            break
        fi
    done
}

prepare_emscripten

# Check if Emscripten is installed and usable
if ! command -v emcc &> /dev/null; then
    print_error "Emscripten is not installed or not in PATH"
    print_info "Install via emsdk (recommended):"
    echo "  git clone https://github.com/emscripten-core/emsdk.git"
    echo "  cd emsdk && ./emsdk install latest && ./emsdk activate latest"
    echo "  source ./emsdk_env.sh"
    exit 1
fi

if ! emcc --version >/dev/null 2>&1; then
    print_error "Emscripten detected but not runnable (often due to Python < 3.10)"
    PYV=$(python3 --version 2>&1 || true)
    print_info "python3: $PYV"
    print_info "Fix: ensure python3 >= 3.10 is first in PATH (brew or pyenv), or use emsdk's environment."
    exit 1
fi

print_info "Emscripten: $(emcc --version | head -n 1)"

# Clone or update ioquake3 repository
if [ -d "$IOQ3_DIR" ]; then
    print_info "$IOQ3_DIR is our working directory.."
    print_info "ioquake3 directory exists, attempting to update..."
    if git -C "$IOQ3_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if git -C "$IOQ3_DIR" ls-remote --exit-code "$IOQ3_REPO" >/dev/null 2>&1; then
            git -C "$IOQ3_DIR" pull --ff-only || print_warning "git pull failed; continuing with local sources"
        else
            print_warning "Remote not reachable; skipping git pull (offline mode)"
        fi
    else
        print_warning "'$IOQ3_DIR' is not a git repo; continuing with local sources"
    fi
else
    print_info "Cloning ioquake3 repository..."
    git clone "$IOQ3_REPO" "$IOQ3_DIR" || {
        print_warning "Clone failed (possibly offline). Create '$IOQ3_DIR' manually or fetch sources before building."
        exit 1
    }
fi

# Apply local overlays if present (do not hand-edit vendor sources)
if [ -d "overlays/ioq3" ]; then
  print_info "Applying local ioq3 overlays (net/WebRTC, cmake flags)"
  rsync -a overlays/ioq3/ "$IOQ3_DIR/"
fi

# Check for game data. Demo is the default because it makes the Forge app
# playable without asking each installer to provide retail Quake III files.
PAK_DIR="$IOQ3_DIR/baseq3"
DEMO_PAK_SRC="$IOQ3_DIR/demoq3/pak0.pk3"
mkdir -p "$PAK_DIR" "$IOQ3_DIR/demoq3"

if $DEMO; then
    if [ ! -f "$DEMO_PAK_SRC" ] && [ -f "demoq3/pak0.pk3" ]; then
        print_info "Copying bundled demo pak into $IOQ3_DIR/demoq3"
        cp -f "demoq3/pak0.pk3" "$DEMO_PAK_SRC"
    fi
    if [ ! -f "$DEMO_PAK_SRC" ]; then
        print_error "Missing Quake III demo data: $DEMO_PAK_SRC"
        print_info "Expected demoq3/pak0.pk3 in this repo or $DEMO_PAK_SRC in ioq3-build."
        exit 1
    fi
    print_info "Found Quake III demo pak0.pk3"
else
    if [ ! -f "$PAK_DIR/pak0.pk3" ]; then
        print_warning "pak0.pk3 not found in $PAK_DIR"
        print_info "Retail/lean builds require your own Quake III PAK files in: $PAK_DIR"
        print_info "Files must be lowercase (pak0.pk3, pak1.pk3, etc.)"
        exit 1
    fi

    print_info "Found baseq3/pak0.pk3"

    if [ -f "$PAK_DIR/pak1.pk3" ]; then
        print_info "Found pak1.pk3 (full version)"
    else
        print_warning "pak1.pk3 not found (base pak only)"
    fi
fi

# Build ioquake3 with Emscripten
print_info "Configuring ioquake3 build..."
mkdir -p "$BUILD_DIR"

if [ -f "$IOQ3_DIR/Makefile" ]; then
    print_info "Makefile detected, building with emmake..."
    cd "$IOQ3_DIR"
    emmake make
else
    print_info "CMake project detected, building with emcmake (preloading files)..."
    # Choose which game dir to use
    PRELOAD_DIR="baseq3"
    if $DEMO; then PRELOAD_DIR="demoq3"; fi
    # For demo, embed data as a single .data (fits under 100MB).
    PRELOAD_FLAG=$([ $PRELOAD -eq 1 ] && echo ON || echo OFF)
    emcmake cmake -S "$IOQ3_DIR" -B "$BUILD_DIR" -DCMAKE_ASM_COMPILER="$(command -v emcc)" -DEMSCRIPTEN_PRELOAD_FILE=$PRELOAD_FLAG -DEMSCRIPTEN_PRELOAD_DIR="$PRELOAD_DIR"

    SOURCE_PRELOAD_DIR="$IOQ3_DIR/$PRELOAD_DIR"

    # Stage baseq3 (at least PAKs) BEFORE any link step so file_packager succeeds
    print_info "Staging ${PRELOAD_DIR} PAKs for initial .data packaging ..."
    rm -rf "$BUILD_DIR/$PRELOAD_DIR"
    mkdir -p "$BUILD_DIR/$PRELOAD_DIR" "$SOURCE_PRELOAD_DIR"
    chmod u+w "$SOURCE_PRELOAD_DIR" 2>/dev/null || true
    if $DEMO; then
      # Demo requires demoq3/pak0.pk3
      if [ -f "$DEMO_PAK_SRC" ]; then
        cp -f "$DEMO_PAK_SRC" "$BUILD_DIR/$PRELOAD_DIR/"
        # Ensure a default.cfg exists for demo mode to satisfy engine startup
        if [ ! -f "$BUILD_DIR/$PRELOAD_DIR/default.cfg" ]; then
          cat > "$BUILD_DIR/$PRELOAD_DIR/default.cfg" <<'EOF'
// Minimal default.cfg for Quake III demo (Emscripten)
unbindall
bind TAB "+scores"
bind ENTER "+button2"
bind ESCAPE "togglemenu"
bind SPACE "+moveup"
bind ` "toggleconsole"
bind ~ "toggleconsole"
bind 1 "weapon 1"
bind 2 "weapon 2"
bind 3 "weapon 3"
bind 4 "weapon 4"
bind 5 "weapon 5"
bind 6 "weapon 6"
bind 7 "weapon 7"
bind 8 "weapon 8"
bind 9 "weapon 9"
bind a "+moveleft"
bind d "+moveright"
bind s "+back"
bind w "+forward"
bind f "+movedown"
bind r "+button3"
bind e "+button5"
bind q "+button6"
bind MOUSE1 "+attack"
bind MOUSE2 "+button2"
bind MOUSE3 "+zoom"
seta cg_fov 90
seta r_mode -2
seta s_volume 0.6
seta m_pitch 0.022
seta sensitivity 4
EOF
        fi
        cp -f "$BUILD_DIR/$PRELOAD_DIR/default.cfg" "$SOURCE_PRELOAD_DIR/default.cfg"
      else
        print_error "Missing demoq3/pak0.pk3 in $IOQ3_DIR/demoq3"
        print_info "Place Quake 3 demo pak0.pk3 at: $IOQ3_DIR/demoq3/pak0.pk3"
        exit 1
      fi
    else
      # Baseq3: always include pak0; optionally add point release
      if [ -f "$PAK_DIR/pak0.pk3" ]; then
          cp -f "$PAK_DIR/pak0.pk3" "$BUILD_DIR/$PRELOAD_DIR/"
      else
          print_error "Missing pak0.pk3 in $PAK_DIR"
          exit 1
      fi
      if $INCLUDE_POINT_RELEASE; then
        for i in 1 2 3 4 5 6 7 8; do
          if [ -f "$PAK_DIR/pak${i}.pk3" ]; then
            cp -f "$PAK_DIR/pak${i}.pk3" "$BUILD_DIR/$PRELOAD_DIR/"
          fi
        done
        print_info "Included point release paks present in $PAK_DIR"
      else
        print_info "Lean mode: only pak0.pk3 will be packaged"
      fi
    fi

    # Build everything (will link ioquake3 and create an initial .data)
    cmake --build "$BUILD_DIR" -j

    # After QVMs have been generated under Release/baseq3/vm, stage them.
    # The demo pak contains old QVMs (UI API v3), while this engine expects the
    # QVMs built with the current source tree (UI API v6). Put current QVMs in
    # the loose demoq3/vm directory so they override the versions inside pak0.
    if [ -d "$BUILD_DIR/Release/baseq3/vm" ]; then
        print_info "Collecting built QVMs..."
        mkdir -p "$BUILD_DIR/$PRELOAD_DIR/vm"
        cp -f "$BUILD_DIR/Release/baseq3/vm"/*.qvm "$BUILD_DIR/$PRELOAD_DIR/vm/" 2>/dev/null || true
        if $DEMO; then
          mkdir -p "$SOURCE_PRELOAD_DIR/vm"
          cp -f "$BUILD_DIR/Release/baseq3/vm"/*.qvm "$SOURCE_PRELOAD_DIR/vm/" 2>/dev/null || true
        fi
        rm -f "$BUILD_DIR/Release/ioquake3.js" "$BUILD_DIR/Release/ioquake3.data" 2>/dev/null || true
        cmake --build "$BUILD_DIR" --target ioquake3 -j
    fi
fi

# Clean previous artifacts to avoid exceeding Forge hosted-resource size
if [ -f ./clean-artifacts.sh ]; then
  print_info "Pre-cleaning static artifacts (quake3)"
  bash ./clean-artifacts.sh --quake3 --purge-static-dirs || true
fi

# Create static directory if it doesn't exist
mkdir -p "$ENGINE_DIR"

print_info "Copying build output to Forge app..."
# Prefer explicit Release artifacts if present; only stage canonical ioquake3.*
PREF_JS="$BUILD_DIR/Release/ioquake3.js"
PREF_WASM="$BUILD_DIR/Release/ioquake3.wasm"
PREF_DATA="$BUILD_DIR/Release/ioquake3.data"

JS_FILE="$PREF_JS"; WASM_FILE="$PREF_WASM"; DATA_FILE="$PREF_DATA"

if [ ! -f "$JS_FILE" ] || [ ! -f "$WASM_FILE" ]; then
  print_error "Could not locate required artifacts (ioquake3.js / ioquake3.wasm)"
  ls -lh "$BUILD_DIR/Release" || true
  exit 1
fi

cp "$JS_FILE" "$ENGINE_DIR/ioquake3.js"
cp "$WASM_FILE" "$ENGINE_DIR/ioquake3.wasm"
if [ -f "$DATA_FILE" ]; then cp "$DATA_FILE" "$ENGINE_DIR/ioquake3.data"; fi

# Copy config for diagnostics. For non-preloaded builds, copy game directories
# so the generated browser glue can fetch files listed in ioquake3-config.json.
PREF_JSON="$BUILD_DIR/Release/ioquake3-config.json"
if [ -f "$PREF_JSON" ]; then
  cp "$PREF_JSON" "$ENGINE_DIR/ioquake3-config.json" || true
fi
if [ $PRELOAD -eq 0 ]; then
  for dir in baseq3 missionpack demoq3 tademo; do
    if [ -d "$BUILD_DIR/Release/$dir" ]; then
      mkdir -p "$FORGE_STATIC_DIR/$dir"
      rsync -a --delete "$BUILD_DIR/Release/$dir/" "$FORGE_STATIC_DIR/$dir/" 2>/dev/null || cp -R "$BUILD_DIR/Release/$dir/." "$FORGE_STATIC_DIR/$dir/"
    fi
  done
fi

# Clean any previously streamed demo assets from static dir
rm -f "$FORGE_STATIC_DIR/demoq3/pak0.pk3.part"* "$FORGE_STATIC_DIR/demoq3/pak0.parts.json" 2>/dev/null || true

# Write basegame selector for the loader
echo "$PRELOAD_DIR" > "$ENGINE_DIR/basegame.txt"

# Verify files were copied
if [ -f "$ENGINE_DIR/ioquake3.js" ] && \
   [ -f "$ENGINE_DIR/ioquake3.wasm" ]; then
    print_info "Build files successfully copied!"
else
    print_error "Failed to copy some build files"
    exit 1
fi

# Show file sizes
print_info "Build file sizes:"
ls -lh "$ENGINE_DIR/ioquake3.js" | awk '{print "  ioquake3.js:   " $5}'
ls -lh "$ENGINE_DIR/ioquake3.wasm" | awk '{print "  ioquake3.wasm: " $5}'
if [ -f "$ENGINE_DIR/ioquake3.data" ]; then ls -lh "$ENGINE_DIR/ioquake3.data" | awk '{print "  ioquake3.data: " $5}'; else echo "  ioquake3.data: (none)"; fi

# Ensure no large preloaded .data remains when PRELOAD=0
if [ $PRELOAD -eq 0 ]; then
  rm -f "$ENGINE_DIR/ioquake3.data" "$ENGINE_DIR/ioquake3.data.gz" 2>/dev/null || true
fi

echo ""
print_info "${GREEN}Build complete!${NC}"
echo ""
print_info "Next steps:"
echo "  1. Test locally:"
echo "     cd $FORGE_STATIC_DIR && python3 -m http.server 8000"
echo "     open http://localhost:8000/"
echo "  2. Deploy to Forge:"
echo "     forge deploy"
echo "     forge install"
echo ""
print_info "To test locally, you can use a local web server:"
echo "  cd $FORGE_STATIC_DIR && python3 -m http.server 8000"
echo ""
