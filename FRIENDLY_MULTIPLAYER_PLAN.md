# Friendly Multiplayer Plan

Date: April 17, 2026

## Project Summary

`/Users/wjk/Code/jira-quake3` is an Atlassian Forge app that serves Quake III Arena as a Custom UI resource for Jira and Confluence. The default path is a self-contained playable demo using `static/quake3/engine/ioquake3.js`, `ioquake3.wasm`, and `ioquake3.data`.

The Forge app currently has two browser multiplayer paths:

- WebSocket relay mode: enabled by the `ws` query parameter. The browser sends binary Quake III packets over WebSocket, and the relay forwards them to a UDP ioquake3 server.
- WebRTC lobby mode: exposed in the `Advanced multiplayer` dropdown. It uses the Forge webtrigger signaling function in `src/signaling.js` to exchange lobby offers, answers, and ICE candidates.

The sibling relay repo at `/Users/wjk/Code/forge-quake3-relay` contains the broader relay stack and documentation. Its `IMPLEMENTATION_SUMMARY.md`, `CHECKLIST.md`, and `docs/DEPLOYMENT.md` describe a production-ready WebSocket-to-UDP relay, Docker Compose ioquake3 server setup, deployment options, monitoring, and the remaining WASM integration steps.

## Current Development State

- Forge runtime is `nodejs22.x`.
- Quake III demo data is packaged into `static/quake3/engine/ioquake3.data`.
- The QVM version mismatch was fixed by staging current `cgame.qvm`, `qagame.qvm`, and `ui.qvm` into the preloaded data.
- The Custom UI wrapper supports automatic WebSocket relay connection when `?ws=wss://...` is present.
- The `Advanced multiplayer` dropdown has Signaling URL and Lobby ID controls for the WebRTC path.
- The dropdown controls now release canvas focus and stop their keyboard/pointer events from leaking into the Quake input handlers.
- Relay auto-connect now uses logical address `10.0.0.1:27960` instead of `127.0.0.1:27960` so ioquake3 performs the normal remote-server challenge handshake through the relay.

## Friendly Multiplayer Checklist

- [x] Keep the current Quake canvas input behavior for normal play.
- [x] Let users type in the Advanced multiplayer fields without Quake consuming keystrokes.
- [x] Fix relay mode getting stuck at "Awaiting connection" by avoiding loopback semantics inside the browser client.
- [ ] Split the multiplayer UI into clear paths:
  - WebSocket relay URL for the Docker/native server path.
  - Signaling URL plus Lobby ID for WebRTC lobby experiments.
- [ ] Wire a WebSocket relay URL field into the existing `proxyUrl` / `?ws=` launch behavior so users do not need to edit the URL manually.
- [ ] Add copyable invite links for both modes with clear labels.
- [ ] Replace deprecated Forge `storage` usage in `src/signaling.js` with the current Forge KVS API.
- [ ] Smoke test in Jira with a reachable `wss://` relay and two browser sessions.
- [ ] Smoke test the WebRTC lobby path separately so it is not confused with the Docker relay path.

## Relay Deployment Notes

From `/Users/wjk/Code/forge-quake3-relay`:

```bash
docker compose up -d --build ioquake3 relay
```

The relay docs describe three deployment paths:

- Single VPS with systemd.
- Docker Compose on a server.
- Kubernetes behind a load balancer.

For Forge/Jira testing, the browser needs a reachable secure WebSocket URL. A local relay must be exposed as `wss://...`, for example through Cloudflare Tunnel or a deployed reverse proxy with TLS.

## Immediate Next Step

Add a visible WebSocket relay URL field to the Forge app, keep it separate from the Signaling URL field, and make the Start/Join flow update the page URL with `?ws=...` before launching Quake networking.
