import Resolver from "@forge/resolver"

const resolver = new Resolver()

resolver.define("getText", (req) => {
  return { text: "Classic games are ready to play!" }
})

resolver.define("handler", (req) => {
  return { text: "Game Loaded" }
})

export const handler = resolver.getDefinitions()
