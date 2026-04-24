# Quake III Forge App And WebSocket Relay Walkthrough

This is a recording script for walking through the Quake III Forge app, the browser networking changes, and the WebSocket-to-UDP relay.

## 1. What This Project Is

This project packages Quake III Arena as an Atlassian Forge Custom UI app.

The app runs inside Jira and Confluence as a static Forge resource. The user opens a Forge page, Forge serves the Custom UI files, and the browser runs an Emscripten/WebAssembly build of ioquake3.

The default experience is single-player/demo mode. Multiplayer is optional and uses a relay because browsers cannot open raw UDP sockets.

Key files to show:

- `manifest.yml`
- `static/quake3/index.html`
- `static/quake3/engine/ioquake3.js`
- `static/quake3/engine/ioquake3.wasm`
- `static/quake3/engine/ioquake3.data`
- `build-ioq3.sh`
- `overlays/ioq3/code/qcommon/net_ip.c`

## 2. Forge App Entry Point

Start with `manifest.yml`.

The manifest declares the Forge modules:

- Jira global page
- Jira issue glance
- Confluence global page
- Webtrigger for the experimental signaling flow

The important resource is:

```yaml
resources:
  - key: quake3
    path: static/quake3
```

That means Forge serves everything under `static/quake3` as the Custom UI app.

The app also allows `unsafe-eval` because Emscripten/WASM glue needs it, and it allowlists the production WebSocket relay host under `permissions.external.fetch.client`.

## 3. Browser Launcher

Next, open `static/quake3/index.html`.

This file is the browser launcher around the engine. It provides:

- The canvas Quake renders into
- The loading/status UI
- Audio unlock handling
- The Advanced multiplayer dropdown
- WebSocket relay controls
- Experimental lobby/signaling controls
- The `Module.q3_rtc` bridge that connects JavaScript networking to the Quake engine

The launcher detects the base game by fetching:

```text
./engine/basegame.txt
```

For the current demo build, this resolves to:

```text
demoq3
```

Then the launcher starts ioquake3 with arguments like:

```text
+set sv_pure 0
+set net_enabled 0 or 1
+set r_mode -2
+set com_basegame demoq3
+set fs_basegame ""
```

When there is no relay URL, `net_enabled` is `0` and the app behaves like a local demo build.

When `?ws=wss://...` is present, `net_enabled` becomes `1`, and the launcher also adds:

```text
+connect 10.0.0.1:27960
```

That `10.0.0.1:27960` address is not the real server. It is a logical address inside the browser client. The actual destination is configured in the relay container.

## 4. Fixing The Multiplayer Input Trap

The Advanced multiplayer dropdown originally had an input problem: Quake captured keyboard and mouse input through the canvas, so typing into relay/lobby fields was unreliable.

The launcher now treats the multiplayer panel as UI, not game input.

In `static/quake3/index.html`, the multiplayer panel listens for keyboard, pointer, touch, and wheel events. If the event starts inside `#multiplayer`, it stops propagation and blurs the canvas.

The important concept is:

```js
const isMultiplayerControl = target =>
  target instanceof Element && target.closest("#multiplayer")
```

This lets the user type WebSocket URLs, signaling URLs, and lobby IDs without Quake consuming the keystrokes.

## 5. Why A Relay Is Needed

Quake III multiplayer uses UDP.

Browsers cannot create UDP sockets from normal web pages. Forge Custom UI runs in a browser iframe, so it has the same limitation.

The solution is to preserve Quake III's UDP protocol, but carry the packets through a browser-safe transport:

```text
Quake III packet
  -> WebAssembly networking overlay
  -> JavaScript Module.q3_rtc
  -> browser WebSocket
  -> Node relay
  -> UDP socket
  -> native ioquake3 dedicated server
```

The relay does not understand Quake gameplay. It forwards bytes.

## 6. What Changed In ioquake3

Open:

```text
overlays/ioq3/code/qcommon/net_ip.c
```

This is the Emscripten-specific networking overlay.

Native ioquake3 normally sends and receives UDP packets through platform socket code. For the browser build, we replace that layer with JavaScript hooks:

```c
q3rtc_ready()
q3rtc_recv()
q3rtc_send()
```

Those hooks call into:

```js
Module.q3_rtc
```

From Quake III's point of view, the engine still calls:

```c
NET_GetPacket()
Sys_SendPacket()
```

From the browser's point of view, those calls become JavaScript send and receive operations.

This keeps the Quake III protocol mostly intact. We are not rewriting the game protocol; we are swapping the transport layer.

## 7. How The JavaScript Transport Works

Back in `static/quake3/index.html`, the active relay transport is created by:

```js
createWebSocketTransport(proxyUrl)
```

That transport exposes:

```js
{
  get isReady() {},
  recv() {},
  send(buf) {}
}
```

The C overlay calls these through `Module.q3_rtc`.

Outgoing path:

```text
Sys_SendPacket
  -> q3rtc_send
  -> Module.q3_rtc.send
  -> WebSocket.send(binary packet)
```

Incoming path:

```text
WebSocket message
  -> queue ArrayBuffer
  -> Module.q3_rtc.recv
  -> q3rtc_recv
  -> NET_GetPacket
```

The active implementation uses binary WebSocket frames. Earlier relay docs discuss JSON/base64 messages, but the current working path is binary and simpler.

## 8. Build Pipeline

Open:

```text
build-ioq3.sh
```

The build script:

1. Ensures Emscripten is available.
2. Clones or updates the ioquake3 source into `ioq3-build`.
3. Applies local overlays from `overlays/ioq3`.
4. Stages the demo `pak0.pk3`.
5. Builds ioquake3 with Emscripten.
6. Produces the Forge-ready engine files under `static/quake3/engine`.

The important rule is that we do not hand-edit generated or vendor output under:

```text
build/
qwasm-build/
ioq3-build/
```

The maintainable patch lives under `overlays/ioq3`.

## 9. Packaged Game Data

The Forge app needs to stay under Forge resource limits.

The current default build packages a playable Quake III demo into:

```text
static/quake3/engine/ioquake3.data
```

At runtime, Emscripten preloads files into the virtual filesystem:

```text
/demoq3/default.cfg
/demoq3/pak0.pk3
/demoq3/vm/cgame.qvm
/demoq3/vm/qagame.qvm
/demoq3/vm/ui.qvm
```

This is why Jira and Confluence users can open the app and play without copying PK3 files.

## 10. Relay Repository

Now switch to the sibling repo:

```text
../forge-quake3-relay
```

The active deployment files are:

- `docker-compose.yml`
- `scripts/relay-server-enhanced.mjs`
- `server.cfg`
- `baseq3/`

The Docker Compose stack runs two services:

```text
ioquake3
relay
```

The `ioquake3` service is the native dedicated Quake III server. It listens on UDP port `27960`.

The `relay` service is a Node process. It listens for WebSocket connections on TCP port `8080` and forwards packet bytes to the game server over UDP.

## 11. Relay Server

Open:

```text
../forge-quake3-relay/scripts/relay-server-enhanced.mjs
```

The relay reads these environment variables:

```text
TARGET_HOST=ioquake3
TARGET_PORT=27960
PROXY_PORT=8080
PROXY_HOST=0.0.0.0
DEBUG=true
```

It exposes two HTTP endpoints:

```text
/
/healthz
```

These are useful for tunnel and deployment checks.

The WebSocket server accepts browser clients. For each browser WebSocket, the relay creates a UDP socket. That one-to-one mapping matters because Quake III identifies clients by UDP source address and port.

Packet forwarding is direct:

```text
WebSocket binary frame -> UDP packet
UDP packet -> WebSocket binary frame
```

No Quake-specific parsing is required in the relay.

## 12. Docker Networking

Open:

```text
../forge-quake3-relay/docker-compose.yml
```

The key detail is that the relay talks to the game server by Docker service name:

```text
TARGET_HOST=ioquake3
TARGET_PORT=27960
```

The public browser connects to the relay:

```text
wss://relay-host.example.com
```

The relay privately forwards to:

```text
ioquake3:27960/udp
```

For local testing, Cloudflare Tunnel or another reverse proxy can expose the relay as `wss://...`.

For production, the relay should run outside Forge. Forge functions are not long-lived WebSocket servers.

## 13. Dedicated Server Configuration

Open:

```text
../forge-quake3-relay/server.cfg
```

This config customizes the native ioquake3 server:

```text
sv_hostname "Forge Quake Relay Arena"
g_motd "Welcome to the Forge relay arena."
sv_pure 0
bot_enable 1
bot_nochat 1
bot_minplayers 0
```

`sv_pure 0` is important for browser/demo/client asset experiments.

`bot_minplayers 0` prevents random automatic bot filling. Instead, the map rotation explicitly adds our named bots:

```text
addbot tankjr 4 free 1 Charlie
addbot keel 4 free 2 Scott
addbot klesk 4 free 3 Mike
```

The maps rotate through:

```text
q3dm17
q3dm1
q3dm7
```

Each map runs the bot-add command.

## 14. Current Custom Model Direction

The next friendly multiplayer enhancement is custom models.

The important rule is that model PK3s must exist on both sides:

1. The native server needs the PK3s under `../forge-quake3-relay/baseq3`.
2. The browser client needs the same PK3s loaded into its virtual game filesystem.

If the server has a model that the browser does not have, the bot may exist in the match but the client will render a fallback or fail to show the intended model.

The planned model work is:

- Add custom model PK3s from `Models/`.
- Add or generate bot definitions for Charlie, Scott, and Mike.
- Load those PK3s into the server container.
- Load those PK3s into the browser app.
- Update `server.cfg` to use the custom bot definitions.

## 15. End-To-End Request Flow

Use this as the final architecture diagram:

```text
User opens Jira app
  -> Forge serves static/quake3
  -> index.html loads ioquake3.js
  -> ioquake3.js loads ioquake3.wasm and ioquake3.data
  -> Quake starts in browser canvas
  -> user enters or opens ?ws=wss://relay-host
  -> index.html creates WebSocket transport
  -> Module.q3_rtc exposes transport to C networking overlay
  -> Quake issues +connect 10.0.0.1:27960
  -> packets leave browser over WebSocket
  -> relay forwards packets over UDP
  -> dedicated ioquake3 server responds
  -> relay sends responses back over WebSocket
  -> browser feeds packets back into Quake
  -> player joins the native Quake III server from inside Jira
```

## 16. What To Emphasize In The Recording

The main design choice is that we did not rewrite Quake III multiplayer.

We kept the Quake III protocol and changed the transport boundary:

```text
Native UDP socket
```

became:

```text
Emscripten C hook -> JavaScript transport -> WebSocket -> UDP relay
```

That makes the browser client compatible with a real ioquake3 dedicated server while staying inside Forge's static Custom UI model.

The relay is deliberately small. It is infrastructure outside Forge, because long-running WebSockets are the wrong shape for Forge functions.

The Forge app remains a static browser app. The game server and relay are separate operational pieces.

## 17. Useful Commands For Demo Or Debugging

From the relay repo:

```bash
docker compose up
docker logs -f quake3-relay
docker logs -f quake3-server
```

Check relay health:

```bash
curl https://relay-host.example.com/healthz
```

Run the Forge app locally:

```bash
npm run serve:quake3
```

Open local relay mode:

```text
http://localhost:8000/?ws=ws://127.0.0.1:8080
```

Open Forge relay mode:

```text
https://your-atlassian-site/.../?ws=wss://relay-host.example.com
```

Rebuild the browser engine:

```bash
npm run build:quake3
```

Deploy the Forge app:

```bash
forge deploy -e development
forge install --upgrade -e development
```
