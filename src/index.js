import Resolver from "@forge/resolver"
import { webTrigger } from "@forge/api"

const resolver = new Resolver()

resolver.define("getText", (req) => {
  return { text: "Classic games are ready to play!" }
})

resolver.define("handler", (req) => {
  return { text: "Game Loaded" }
})

resolver.define("getSignalingUrl", async () => {
  const url = await webTrigger.getUrl("q3-signaling")
  return { url }
})

export const handler = resolver.getDefinitions()
