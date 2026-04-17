#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR ]${NC} $*"; exit 1; }

usage() {
  cat <<EOF
Clean old build artifacts from static/ and local build dirs

Usage: $0 [--quake3] [--doom] [--quake] [--all] [--deep] [--purge-static-dirs] [--dry-run]

Flags:
  --quake3            Clean Quake III artifacts (static/quake3)
  --doom              Clean DOOM artifacts (static/doom)
  --quake             Clean Quake (Q1) artifacts (static/quake)
  --all               Clean all of the above (default if none specified)
  --deep              Also remove local build dirs (ioq3 emscripten, Dwasm wasm)
  --purge-static-dirs Remove generated static subdirs (quake3/{baseq3,missionpack,demoq3,tademo})
  --dry-run           Show what would be removed without deleting
  -h, --help          Show this help

Examples:
  $0 --quake3                 # Clean Quake III static artifacts only
  $0 --all --deep             # Clean static artifacts + local build dirs
  $0 --quake3 --purge-static-dirs  # Also purge static/quake3 demo/base folders
EOF
}

do_quake3=false
do_doom=false
do_quake=false
deep=false
purge_static_dirs=false
dry_run=false

if [ $# -eq 0 ]; then
  do_quake3=true; do_doom=true; do_quake=true
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quake3) do_quake3=true; shift ;;
    --doom)   do_doom=true; shift ;;
    --quake)  do_quake=true; shift ;;
    --all)    do_quake3=true; do_doom=true; do_quake=true; shift ;;
    --deep)   deep=true; shift ;;
    --purge-static-dirs) purge_static_dirs=true; shift ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Unknown flag: $1"; usage; exit 2 ;;
  esac
done

rm_path() {
  local p="$1"
  if [ -e "$p" ]; then
    if $dry_run; then
      echo "DRY: rm -rf $p"
    else
      rm -rf "$p"
    fi
  fi
}

clean_quake3() {
  local root="static/quake3"
  info "Cleaning Quake III artifacts under $root"
  # Common top-level artifacts (friendly + original names + gz)
  for f in \
    "$root/index.js" "$root/index.wasm" "$root/index.data" \
    "$root/ioquake3.js" "$root/ioquake3.wasm" "$root/ioquake3.data" \
    "$root/index.js.gz" "$root/index.wasm.gz" "$root/index.data.gz" \
    "$root/ioquake3.js.gz" "$root/ioquake3.wasm.gz" "$root/ioquake3.data.gz" \
    "$root/basegame.txt" \
    ; do rm_path "$f"; done
  # Any stray .data/.wasm/.js from prior builds
  for f in "$root"/*.data "$root"/*.wasm "$root"/*.js "$root"/*.gz; do
    [ -e "$f" ] && rm_path "$f"
  done
  # Old streamed demo artifacts
  for f in "$root/demoq3/pak0.pk3" "$root/demoq3/pak0.parts.json" "$root/demoq3"/pak0.pk3.part*; do
    [ -e "$f" ] && rm_path "$f"
  done
  # Optionally purge generated subdirs copied from build outputs
  if $purge_static_dirs; then
    for d in baseq3 missionpack demoq3 tademo; do
      rm_path "$root/$d"
    done
  fi
}

clean_doom() {
  local root="static/doom"
  info "Cleaning DOOM artifacts under $root"
  for f in \
    "$root/index.js" "$root/index.wasm" "$root/index.data" \
    "$root/doomgeneric.js" "$root/doomgeneric.wasm" "$root/doomgeneric.data" \
    "$root/index.js.gz" "$root/index.wasm.gz" "$root/index.data.gz" \
    "$root/doomgeneric.js.gz" "$root/doomgeneric.wasm.gz" "$root/doomgeneric.data.gz" \
    ; do rm_path "$f"; done
  for f in "$root"/*.data "$root"/*.wasm "$root"/*.js "$root"/*.gz; do
    [ -e "$f" ] && rm_path "$f"
  done
}

clean_quake() {
  local root="static/quake"
  info "Cleaning Quake (Q1) artifacts under $root"
  for f in \
    "$root/index.js" "$root/index.wasm" "$root/index.data" \
    "$root/index.js.gz" "$root/index.wasm.gz" "$root/index.data.gz" \
    ; do rm_path "$f"; done
  for f in "$root"/*.data "$root"/*.wasm "$root"/*.js "$root"/*.gz; do
    [ -e "$f" ] && rm_path "$f"
  done
}

deep_clean() {
  info "Deep cleaning local build directories"
  # ioquake3 emscripten build dir
  rm_path "ioq3-build/build/emscripten"
  # Dwasm wasm build dir
  rm_path "build/Dwasm/build_wasm"
  # Qwasm WinQuake generated WASM glue (keep repo, remove outputs)
  for f in \
    "qwasm-build/WinQuake/index.js" \
    "qwasm-build/WinQuake/index.wasm" \
    "qwasm-build/WinQuake/index.data" \
    ; do rm_path "$f"; done
}

$do_quake3 && clean_quake3
$do_doom   && clean_doom
$do_quake  && clean_quake

if $deep; then
  deep_clean
fi

info "Done."

