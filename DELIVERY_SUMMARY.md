# Quake III Forge App Delivery Summary

Date: April 16, 2026

## Goal

Deliver a playable Quake III demo inside Atlassian Forge Custom UI, with a path toward multiplayer through a WebSocket-to-UDP relay that connects browser clients to an ioquake3 server.

## Repositories

- Forge app: `/Users/wjk/Code/jira-quake3`
- Relay stack: `/Users/wjk/Code/forge-quake3-relay`

## Delivered

### Forge App

- Deployed the Forge app to the development environment as version `3.2.0`.
- Confirmed development installs are on the latest version for:
  - Jira on `a9data.atlassian.net`
  - Confluence on `a9data.atlassian.net`
  - Jira on `one-atlas-ddag.atlassian.net`
- Added Quake III as a Forge Custom UI surface for Jira and Confluence.
- Updated the app runtime to `nodejs22.x`.
- Packaged the browser build under `static/quake3/engine` to keep the hosted resource organized and under Forge hosted-resource limits.

### Browser Quake III Runtime

- Built ioquake3 for WebAssembly with Emscripten.
- Packaged the Quake III demo data into `engine/ioquake3.data`.
- Fixed the fatal demo startup crash:
  - Old demo `pak0.pk3` contains QVMs with UI API version `3`.
  - The current engine expects UI API version `6`.
  - The build now stages freshly built `cgame.qvm`, `qagame.qvm`, and `ui.qvm` into `demoq3/vm` so they override the old QVMs inside the demo pak.
- Verified generated loader metadata includes:
  - `/demoq3/default.cfg`
  - `/demoq3/pak0.pk3`
  - `/demoq3/vm/cgame.qvm`
  - `/demoq3/vm/qagame.qvm`
  - `/demoq3/vm/ui.qvm`

### Forge CSP Cleanup

- Removed inline `style` attributes from the Custom UI HTML.
- Moved those styles into `static/quake3/styles.css`.
- Fixed the app-side `style-src` CSP violations shown in the Forge iframe logs.
- Stopped probing `./demoq3/pak0.pk3` when `engine/ioquake3.data` is present, removing the expected-but-noisy `404` HEAD request.

### Multiplayer Transport Work

- Implemented browser transport hooks in the ioquake3 overlay so the engine can send and receive packets through JavaScript.
- Added WebSocket transport support in the Custom UI when a WebSocket relay URL is provided.
- Added auto-connect behavior for the relay path:
  - When a WebSocket proxy is supplied, the engine starts with networking enabled.
  - The client auto-runs `+connect 10.0.0.1:27960`.
  - That address is logical inside the browser build; packets are carried by the WebSocket relay to the real UDP server.
- Kept the existing WebRTC/signaling lobby code path, but clarified that it is separate from the Docker WebSocket relay path.

### Relay Stack

- Confirmed the relay repository has a Docker Compose stack with:
  - `quake3-server` running UDP Quake III on port `27960`.
  - `quake3-relay` running the WebSocket-to-UDP relay on port `8080`.
- Earlier relay end-to-end verification passed with `npm run test:e2e:q3:run`.

## Important Fixes

### QVM Version Mismatch

Browser logs showed:

```text
ERROR: User Interface is version 3, expected 6
recursive error after: User Interface is version 3, expected 6
```

Root cause:

- The demo pak included old `vm/ui.qvm`.
- ioquake3 loaded that old QVM from `./demoq3/pak0.pk3`.
- The engine expected newer QVM APIs.

Fix:

- Build current QVMs.
- Copy them into the Emscripten preload source directory under `demoq3/vm`.
- Force relink/repackage of `ioquake3.data`.

### Forge Inline Style CSP Blocks

Browser logs showed blocked inline styles from the Custom UI iframe.

Fix:

- Replaced inline styles with CSS classes.
- Updated JavaScript to toggle classes instead of setting `style.display`.

### Demo Pak Probe 404

Browser logs showed:

```text
HEAD .../demoq3/pak0.pk3 ... 404
```

Root cause:

- The app checked for both preloaded `.data` and loose `pak0.pk3`.
- The deployed app intentionally uses preloaded `.data`.

Fix:

- Only probe loose `pak0.pk3` if `engine/ioquake3.data` is absent.

## Verification Completed

Commands run successfully:

```bash
npm run build:quake3
forge lint
forge deploy -e development --verbose
```

Build outputs:

```text
static/quake3/engine/ioquake3.js
static/quake3/engine/ioquake3.wasm
static/quake3/engine/ioquake3.data
```

Forge lint result:

- `0` errors.
- `1` existing warning: `src/signaling.js` uses deprecated `storage` from `@forge/api`.

Deployment result:

- Forge development deployment succeeded.
- Latest deployed app version: `3.2.0`.

## Current Multiplayer Test Path

Start the relay stack:

```bash
cd /Users/wjk/Code/forge-quake3-relay
docker compose up -d --build ioquake3 relay
```

Check logs:

```bash
docker logs -f quake3-relay
docker logs -f quake3-server
```

Expose the relay as WSS for Jira:

```bash
cloudflared tunnel --url http://localhost:8080
```

Use the printed HTTPS tunnel host as a WebSocket URL:

```text
https://example.trycloudflare.com -> wss://example.trycloudflare.com
```

The current app code supports the WebSocket relay through the `ws` query parameter. If the app dialog has a WebSocket proxy field, paste the `wss://...` URL there. If it only has the Signaling URL field, that field is for the WebRTC signaling path and is not the same as the Docker WebSocket relay.

## Remaining Work

- Clarify the multiplayer UI:
  - Add an explicit `WebSocket relay URL` field for the Docker relay path.
  - Keep `Signaling URL` labeled separately for WebRTC lobby signaling.
- Wire the WebSocket relay field directly to the existing `proxyUrl` logic so manual `?ws=...` URL editing is unnecessary.
- Replace deprecated Forge storage usage in `src/signaling.js` with `@forge/kvs`.
- Run a fresh Jira browser test after CDN propagation:
  - Confirm no `User Interface is version 3, expected 6` crash.
  - Confirm no app-side inline style CSP blocks.
  - Confirm WebSocket relay connects from Jira using `wss://...`.
  - Confirm two browser sessions can join the same Quake server.

## Known Non-Blocking Warnings

- Atlassian host-page CSP report-only warnings about `unsafe-eval`.
- Atlassian FeatureGate duplicate-client warning.
- Browser `ScriptProcessorNode` deprecation from the Emscripten/OpenAL audio path.
- Forge Runs on Atlassian ineligibility due to the webtrigger egress rule.
