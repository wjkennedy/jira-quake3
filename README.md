# Quake III Arena for Jira and Confluence

Playable Quake III demo packaged as an Atlassian Forge Custom UI app.

The default build includes the Quake III demo data in `static/quake3/engine/ioquake3.data`, so Jira and Confluence users can open the app and play without copying PK3 files, running a local server, or reading setup notes.

## Quick Start

```bash
npm install
npm run build:quake3
npm run serve:quake3
```

Open:

```text
http://localhost:8000/
```

## Deploy To Forge

```bash
forge login
forge register
forge deploy
forge install
```

The app is available as:

- Jira global page: Quake III Arena
- Jira issue glance: Quake III
- Confluence global page: Quake III Arena

## Multiplayer Relay

Single-player demo mode is the default playable experience. To test the WebSocket-to-UDP relay, run a Q3 server and relay, then open the client with `?ws=`:

```text
http://localhost:8000/?ws=ws://127.0.0.1:8080
```

When `?ws=` is present, the launcher enables networking and connects through the relay automatically.

## Build Modes

Default playable demo:

```bash
./build-ioq3.sh
```

Retail/local asset mode:

```bash
./build-ioq3.sh --lean
```

Retail mode requires your own `ioq3-build/baseq3/pak0.pk3`. Do not ship retail PK3s in a Forge app unless you have the rights to distribute them.

## Troubleshooting

If the page says `Playable data is missing`, run:

```bash
npm run build:quake3
```

Then verify these files exist:

```text
static/quake3/engine/ioquake3.js
static/quake3/engine/ioquake3.wasm
static/quake3/engine/ioquake3.data
```

If Forge shows an older client, redeploy and hard-refresh the Atlassian page.
