#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
  cat <<EOF
Unified build frontend

Usage: $0 <doom|quake|quake3|all> [--webgl] [--no-compress]

Examples:
  $0 quake3                    Build playable Quake III demo into static/quake3
  $0 quake --webgl             Build Quake (Q1) with WebGL (needs GL4ES_PATH)
  $0 all                       Build DOOM, Quake, and Quake III

Flags:
  --webgl        Use WebGL build (Quake 1 only; requires GL4ES_PATH)
  --no-compress  Skip gzip compression step where scripts support it
EOF
}

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR ]${NC} $*"; exit 1; }

cmd=${1:-}
shift || true

webgl=false
compress=true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --webgl) webgl=true; shift ;;
    --no-compress) compress=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Unknown flag: $1"; usage; exit 2 ;;
  esac
done

require_emscripten() {
  # Try to auto-source emsdk if emcc is not present
  if ! command -v emcc >/dev/null 2>&1; then
    local candidates=()
    if [ -n "${EMSDK:-}" ]; then
      candidates+=("$EMSDK")
    fi
    candidates+=("$HOME/emsdk")
    for d in "${candidates[@]}"; do
      if [ -f "$d/emsdk_env.sh" ]; then
        info "Sourcing emsdk environment from $d"
        # shellcheck disable=SC1090
        . "$d/emsdk_env.sh" >/dev/null
        break
      fi
    done
  fi
  if ! command -v emcc >/dev/null 2>&1; then
    error "Emscripten not found. Activate emsdk (source emsdk_env.sh) or set EMSDK=/path/to/emsdk."
  fi
  info "Emscripten: $(emcc --version | head -n1)"
}

run_doom() {
  require_emscripten
  chmod +x ./build-doom.sh
  info "Building DOOM..."
  ./build-doom.sh
  info "DOOM artifacts in static/doom"
}

run_quake() {
  require_emscripten
  chmod +x ./build-quake.sh
  if $webgl; then
    [[ -n "${GL4ES_PATH:-}" ]] || error "--webgl requires GL4ES_PATH to be set"
    info "Building Quake (WebGL) with GL4ES at $GL4ES_PATH..."
    ./build-quake.sh webgl
  else
    info "Building Quake (software renderer)..."
    ./build-quake.sh
  fi
  if ! $compress; then
    warn "Skipping compression (if created)."
  fi
  info "Quake artifacts in static/quake"
}

run_quake3() {
  require_emscripten
  chmod +x ./build-ioq3.sh
  info "Building Quake III demo (ioquake3 Emscripten + packaged demo data)..."
  ./build-ioq3.sh --demo --preload
  info "Quake III artifacts in static/quake3"
  # Manifest sanity check
  if ! rg -n "^\s*-\s*key:\s*quake3\b" manifest.yml >/dev/null 2>&1; then
    warn "manifest.yml missing resource key 'quake3'. Update resources -> key: quake3, path: static/quake3"
  fi
}

case "$cmd" in
  doom)   run_doom ;;
  quake)  run_quake ;;
  quake3) run_quake3 ;;
  all)
    run_doom
    run_quake
    run_quake3
    ;;
  *) usage; exit 2 ;;
esac

info "Done."
