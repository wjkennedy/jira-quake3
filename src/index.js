import Resolver from "@forge/resolver"
import { storage } from "@forge/api"

const resolver = new Resolver()

resolver.define("macroHandler", async (req) => {
  const { context } = req
  const macroId = context.extension.macro?.macroId || "default"

  // Return the macro configuration with unique ID
  return {
    macroId,
    message: "Lotus 1-2-3 Spreadsheet Ready",
  }
})

resolver.define("resolveMacro", async (req) => {
  const { context } = req
  const macroId = context.extension.macro?.macroId || "default"

  // Load saved spreadsheet data if exists
  const savedData = await storage.get(`lotus123-${macroId}`)

  return {
    macroId,
    savedData: savedData || null,
  }
})

resolver.define("saveSpreadsheet", async (req) => {
  const { macroId, data } = req.payload

  try {
    await storage.set(`lotus123-${macroId}`, data)
    return { success: true, message: "Spreadsheet saved successfully" }
  } catch (error) {
    console.error("[v0] Error saving spreadsheet:", error)
    return { success: false, message: "Failed to save spreadsheet" }
  }
})

resolver.define("loadSpreadsheet", async (req) => {
  const { macroId } = req.payload

  try {
    const data = await storage.get(`lotus123-${macroId}`)
    return { success: true, data: data || null }
  } catch (error) {
    console.error("[v0] Error loading spreadsheet:", error)
    return { success: false, message: "Failed to load spreadsheet" }
  }
})

export const handler = resolver.getDefinitions()
