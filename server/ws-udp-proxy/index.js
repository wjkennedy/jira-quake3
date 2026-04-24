#!/usr/bin/env node
"use strict";

// Minimal WebSocket ↔ UDP proxy for Quake 3
// Inspired by q3js ws-udp-proxy. Bridges raw UDP datagrams to/from a browser
// WebSocket so a WASM client can speak to a native ioq3ded server.

const http = require("http");
const dgram = require("dgram");
const { WebSocketServer } = require("ws");

const WS_PORT = Number(process.env.WS_PORT || 27961);
const Q3_HOST = process.env.Q3_HOST || "127.0.0.1";
const Q3_PORT = Number(process.env.Q3_PORT || 27960);

const server = http.createServer();
const wss = new WebSocketServer({ server });

function log(...args) {
  // Simple timestamped logs
  const ts = new Date().toISOString();
  console.log(`[ws-udp ${ts}]`, ...args);
}

wss.on("connection", (ws, req) => {
  const ip = req.socket.remoteAddress;
  log(`client connected from ${ip}`);
  ws.binaryType = "arraybuffer";

  // Per-connection UDP socket (isolates client traffic)
  const udp = dgram.createSocket("udp4");
  let closed = false;

  const cleanup = () => {
    if (closed) return;
    closed = true;
    try { udp.close(); } catch (_) {}
    try { ws.terminate(); } catch (_) {}
    log(`client disconnected ${ip}`);
  };

  udp.on("message", (msg) => {
    if (ws.readyState === ws.OPEN) {
      ws.send(msg);
    }
  });

  udp.on("error", (err) => {
    log("UDP error:", err.message);
    cleanup();
  });

  ws.on("message", (data) => {
    if (typeof data === "string") {
      // Optional ping/keepalive or simple commands
      if (data === "ping") ws.send("pong");
      return;
    }
    const buf = Buffer.isBuffer(data) ? data : Buffer.from(new Uint8Array(data));
    udp.send(buf, Q3_PORT, Q3_HOST);
  });

  ws.on("close", cleanup);
  ws.on("error", (err) => {
    log("WS error:", err.message);
    cleanup();
  });
});

server.listen(WS_PORT, () => {
  log(`listening on ws://0.0.0.0:${WS_PORT} → udp://${Q3_HOST}:${Q3_PORT}`);
});

