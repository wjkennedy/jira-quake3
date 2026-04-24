# Quake III Relay Mode

The Forge app is playable without multiplayer setup. Relay mode is optional and only needed when you want the browser client to connect to a native Quake III UDP server.

## Local Relay Test

1. Start a Quake III server on UDP `27960`.

2. Start the WebSocket relay:

```bash
WS_PORT=27961 Q3_HOST=127.0.0.1 Q3_PORT=27960 npm run ws-proxy
```

3. Serve the browser client:

```bash
npm run serve:quake3
```

4. Open:

```text
http://localhost:8000/?ws=ws://127.0.0.1:27961
```

The launcher adds `+connect 10.0.0.1:27960` automatically when `?ws=` is present. This is a logical in-browser address; the WebSocket relay still forwards packets to the configured UDP server.

## Forge Relay Test

Forge pages cannot connect to a developer machine at `127.0.0.1`. Use a reachable `wss://` relay URL:

```text
https://your-atlassian-site/.../?ws=wss://your-relay.example.com
```

For production, run the relay outside Forge because Forge functions are not long-lived WebSocket servers.

## Notes

- The browser sends raw Quake III packets over binary WebSocket frames.
- The relay forwards those frames to UDP and returns UDP packets to the same browser connection.
- Master server lookup errors are irrelevant in relay mode because the launcher connects directly to the relay-backed server.
