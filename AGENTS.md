# Repository Guidelines

## Project Structure & Module Organization
- App config: `manifest.yml` (Forge modules, resources).
- Serverless code: `src/index.js` (Forge resolver handlers).
- Static game assets: `static/doom`, `static/quake`, `static/quake3`, `static/lotus123` (HTML/CSS/WASM/data).
- Build scripts: `build-doom.sh`, `build-quake.sh`, `build-ioq3.sh`, `pack-ioq3.sh` (generate/copy WASM bundles).
- Vendor sources (read-only): `qwasm-build/`, `ioq3-build/`, `build/` (clones/artifacts). Do not hand-edit generated files.

## Build, Test, and Development Commands
- Build DOOM bundle: `chmod +x build-doom.sh && ./build-doom.sh` (compiles doomgeneric, copies into `static/doom`).
- Build Quake/Quake III: `./build-quake.sh`, `./build-ioq3.sh` (requires Emscripten/toolchain; see READMEs).
- Local run (Forge tunnel): `forge login` → `forge tunnel` (serves static resources and handlers).
- Deploy & install: `forge deploy` → `forge install` (then select site/environment).

## Coding Style & Naming Conventions
- JavaScript/TypeScript: 2-space indent, trailing commas where sensible, double quotes, avoid semicolons in `src/` to match current style.
- Functions/variables: `camelCase`; constants: `UPPER_SNAKE_CASE`.
- Files: scripts `kebab-case` (e.g., `build-ioq3.sh`); static asset folders lowercase.
- Do not rename generated filenames (e.g., `.wasm`, `.data`, `.js`)—wrappers should adapt instead.

## Testing Guidelines
- No formal test suite. Perform smoke tests via `forge tunnel`:
  - Load each page in `static/*/index.html` route and verify canvas renders, audio unlock prompt, and input.
  - Check browser console for errors and network 404s for `.wasm`/`.data`.
- If adding tests, prefer lightweight Node/Playwright smoke checks under `tests/` named `feature-name.spec.ts`.

## Commit & Pull Request Guidelines
- Commits: concise, imperative subject; include scope where helpful. Example: `build(doom): refresh wasm and data`
- PRs must include: purpose, user-visible impact, testing steps (tunnel URL and screenshots), and related issue IDs.
- Keep diffs focused. Exclude large generated blobs from review when possible; describe how to reproduce builds.

## Security & Configuration Tips
- Keep `manifest.yml` modules/resources in sync (resource keys and paths must match). Example keys: `jira:globalPage` → `resources.key`.
- Avoid modifying CSP unnecessarily; current config uses `content.scripts: ['unsafe-eval']` for WASM glue—do not broaden further without review.
- Large assets: prefer gzip where supported (`static/quake/*.wasm.gz`).

## Agent-Specific Instructions
- Never edit files under `build/`, `qwasm-build/`, or `ioq3-build/` directly; change sources upstream and rebuild.
- Update this document and READMEs when build steps or paths change.
