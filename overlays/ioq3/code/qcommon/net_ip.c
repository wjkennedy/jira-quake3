// Overlay: browser packet transport for Emscripten client.
// The JavaScript side exposes Module.q3_rtc with send/recv/isReady. That object
// may be backed by WebSocket or WebRTC; the C side only sees packet datagrams.
#include "../qcommon/q_shared.h"
#include "../qcommon/qcommon.h"

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#include <string.h>
#include <arpa/inet.h>

// JS bridge: implemented by static/quake3/index.html via Module.q3_rtc
EM_JS(int, q3rtc_ready, (void), { return (Module.q3_rtc && Module.q3_rtc.isReady) ? 1 : 0; });
EM_JS(int, q3rtc_recv, (void* dst, int max), {
  if(!Module.q3_rtc||!Module.q3_rtc.recv) return 0;
  var pkt = Module.q3_rtc.recv();
  if(!pkt) return 0;
  var n = Math.min(pkt.byteLength, max);
  HEAPU8.set(new Uint8Array(pkt, 0, n), dst);
  return n;
});
EM_JS(void, q3rtc_send, (void* data, int len), {
  if(!Module.q3_rtc||!Module.q3_rtc.send) return;
  var buf = HEAPU8.slice ? HEAPU8.slice(data, data+len) : HEAPU8.subarray(data, data+len).slice(0);
  Module.q3_rtc.send(buf);
});

static qboolean rtc_active = qfalse;
static netadr_t rtc_remote;
static qboolean rtc_remote_set = qfalse;

static void NET_SetDefaultRemote(netadr_t *adr) {
    memset(adr, 0, sizeof(*adr));
    adr->type = NA_IP;
    adr->ip[0] = 127;
    adr->ip[1] = 0;
    adr->ip[2] = 0;
    adr->ip[3] = 1;
    adr->port = htons(27960);
}

qboolean NET_GetPacket(netadr_t *net_from, msg_t *net_message, void *unused) {
    if(!rtc_active){ rtc_active = q3rtc_ready() ? qtrue : qfalse; }
    if(rtc_active){
        int n = q3rtc_recv(net_message->data, net_message->maxsize);
        if(n > 0){
            if (rtc_remote_set) {
                *net_from = rtc_remote;
            } else {
                NET_SetDefaultRemote(net_from);
            }
            net_message->readcount = 0;
            net_message->cursize = n;
            return qtrue;
        }
    }
    return qfalse;
}

void Sys_SendPacket( int length, const void *data, netadr_t to ) {
    if(!rtc_active){ rtc_active = q3rtc_ready() ? qtrue : qfalse; }
    if(rtc_active){
        rtc_remote = to;
        rtc_remote_set = qtrue;
        q3rtc_send((void*)data, length);
        return;
    }
}

void NET_Sleep(int msec) {
    if(msec > 0) emscripten_sleep(msec);
}

void NET_Init( void ) { }
void NET_Shutdown( void ) { }

// ---- Minimal address helpers expected by server/client code ----
static char adr_buf[NET_ADDRSTRMAXLEN];

const char *NET_AdrToString (netadr_t a)
{
    if (a.type == NA_LOOPBACK) {
        Q_strncpyz(adr_buf, "loopback", sizeof(adr_buf));
    } else if (a.type == NA_BOT) {
        Q_strncpyz(adr_buf, "bot", sizeof(adr_buf));
    } else if (a.type == NA_IP) {
        Com_sprintf(adr_buf, sizeof(adr_buf), "%u.%u.%u.%u",
            a.ip[0], a.ip[1], a.ip[2], a.ip[3]);
    } else if (a.type == NA_IP6) {
        Com_sprintf(adr_buf, sizeof(adr_buf), "::");
    } else {
        Q_strncpyz(adr_buf, "unknown", sizeof(adr_buf));
    }
    return adr_buf;
}

const char *NET_AdrToStringwPort (netadr_t a)
{
    static char s[NET_ADDRSTRMAXLEN];
    if (a.type == NA_LOOPBACK) {
        Com_sprintf(s, sizeof(s), "loopback");
    } else if (a.type == NA_BOT) {
        Com_sprintf(s, sizeof(s), "bot");
    } else if (a.type == NA_IP) {
        Com_sprintf(s, sizeof(s), "%s:%hu", NET_AdrToString(a), ntohs(a.port));
    } else if (a.type == NA_IP6) {
        Com_sprintf(s, sizeof(s), "[%s]:%hu", NET_AdrToString(a), ntohs(a.port));
    } else {
        Com_sprintf(s, sizeof(s), "unknown");
    }
    return s;
}

qboolean NET_CompareBaseAdrMask(netadr_t a, netadr_t b, int netmask)
{
    // Minimal compare: match type and raw bytes ignoring port when IPv4
    if (a.type != b.type) return qfalse;
    if (a.type == NA_LOOPBACK || a.type == NA_BOT) return qtrue;
    if (a.type == NA_IP) {
        return memcmp(a.ip, b.ip, sizeof(a.ip)) == 0 ? qtrue : qfalse;
    }
    if (a.type == NA_IP6) {
        return memcmp(a.ip6, b.ip6, sizeof(a.ip6)) == 0 ? qtrue : qfalse;
    }
    return qfalse;
}

qboolean NET_CompareBaseAdr (netadr_t a, netadr_t b)
{
    return NET_CompareBaseAdrMask(a, b, -1);
}

qboolean NET_CompareAdr (netadr_t a, netadr_t b)
{
    if (!NET_CompareBaseAdr(a, b)) return qfalse;
    if (a.type == NA_IP || a.type == NA_IP6) return a.port == b.port ? qtrue : qfalse;
    return qtrue;
}

qboolean NET_IsLocalAddress( netadr_t adr )
{
    if (adr.type == NA_LOOPBACK) return qtrue;
    if (adr.type == NA_IP && adr.ip[0] == 127) return qtrue;
    return qfalse;
}

qboolean Sys_IsLANAddress( netadr_t adr )
{
    if (adr.type == NA_LOOPBACK) return qtrue;
    if (adr.type == NA_IP) {
        if (adr.ip[0] == 10) return qtrue;
        if (adr.ip[0] == 172 && (adr.ip[1] & 0xF0) == 16) return qtrue;
        if (adr.ip[0] == 192 && adr.ip[1] == 168) return qtrue;
        if (adr.ip[0] == 127) return qtrue;
    }
    return qfalse;
}

qboolean Sys_StringToAdr( const char *s, netadr_t *a, netadrtype_t family )
{
    // Minimal parser: support "loopback" and dotted IPv4 without DNS
    if (!s || !*s) return qfalse;
    if (!Q_stricmp(s, "loopback")) { memset(a, 0, sizeof(*a)); a->type = NA_LOOPBACK; return qtrue; }
    unsigned int b0, b1, b2, b3, port = 27960; char extra;
    if (sscanf(s, "%u.%u.%u.%u:%u%c", &b0,&b1,&b2,&b3,&port,&extra) >= 4 ||
        sscanf(s, "%u.%u.%u.%u%c", &b0,&b1,&b2,&b3,&extra) >= 4) {
        if (b0 > 255 || b1 > 255 || b2 > 255 || b3 > 255 || port > 65535) {
            return qfalse;
        }
        memset(a, 0, sizeof(*a));
        a->type = NA_IP;
        a->ip[0]=b0;
        a->ip[1]=b1;
        a->ip[2]=b2;
        a->ip[3]=b3;
        a->port = htons((short)port);
        return qtrue;
    }
    return qfalse;
}

void NET_Config( qboolean enableNetworking ) { (void)enableNetworking; }
void NET_Restart_f(void) { }

// Multicast stubs (no-op under WebRTC)
void NET_JoinMulticast6(void) { }
void NET_LeaveMulticast6(void) { }

// Show local IPs (optional; keep minimal)
void Sys_ShowIP(void) {
    // We can’t enumerate OS interfaces in the browser; print a placeholder.
    Com_Printf("IP: 127.0.0.1 (wasm)\n");
}

#else
#error "Emscripten-only overlay"
#endif
