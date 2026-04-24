// Use storage API (supported) instead of @forge/kvs for compatibility
import { storage } from '@forge/api'

function lobbyKey(id){ return `q3:lobby:${id}` }

async function getLobby(id){
  const k = lobbyKey(id)
  const doc = await storage.get(k)
  return doc || { id, offers: [], answers: [], ice: [], createdAt: Date.now() }
}

async function putLobby(state){
  await storage.set(lobbyKey(state.id), state)
  return state
}

function randomId(len=8){
  const alpha = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  let out = ''
  for(let i=0;i<len;i++) out += alpha[Math.floor(Math.random()*alpha.length)]
  return out
}

export async function run(event, context){
  try {
    const method = (event.request?.method || 'POST').toUpperCase()
    const body = event.body ? JSON.parse(event.body) : {}
    const action = body.action || event.queryParameters?.action?.[0] || 'get'

    if(action === 'create'){
      const id = body.lobbyId || randomId()
      const state = await getLobby(id)
      state.id = id; state.createdAt = Date.now()
      await putLobby(state)
      return { statusCode: 200, body: JSON.stringify({ ok: true, lobbyId: id }) }
    }

    const lobbyId = body.lobbyId || event.queryParameters?.lobbyId?.[0]
    if(!lobbyId){
      return { statusCode: 400, body: JSON.stringify({ ok: false, error: 'missing lobbyId' }) }
    }
    const state = await getLobby(lobbyId)

    if(action === 'offer'){
      const { peerId, sdp } = body
      if(peerId && sdp){ state.offers.push({ peerId, sdp, t: Date.now() }); await putLobby(state) }
      return { statusCode: 200, body: JSON.stringify({ ok: true }) }
    }

    if(action === 'answer'){
      const { peerId, sdp } = body
      if(peerId && sdp){ state.answers.push({ peerId, sdp, t: Date.now() }); await putLobby(state) }
      return { statusCode: 200, body: JSON.stringify({ ok: true }) }
    }

    if(action === 'ice'){
      const { from, to, candidate } = body
      if(from && to && candidate){ state.ice.push({ from, to, candidate, t: Date.now() }); await putLobby(state) }
      return { statusCode: 200, body: JSON.stringify({ ok: true }) }
    }

    // Default: get full state snapshot
    return { statusCode: 200, body: JSON.stringify({ ok: true, lobby: state }) }
  } catch (e){
    return { statusCode: 500, body: JSON.stringify({ ok: false, error: e.message }) }
  }
}
