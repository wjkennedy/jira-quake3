import Resolver from "@forge/resolver"

const resolver = new Resolver()

resolver.define("getText", (req) => {
  return { text: "DOOM is ready to play!" }
})

resolver.define("handler", (req) => {
  return { text: "DOOM Game Loaded" }
})

export const handler = resolver.getDefinitions()
