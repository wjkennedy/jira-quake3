// Lotus 1-2-3 Spreadsheet Engine
class LotusEngine {
  constructor() {
    this.canvas = document.getElementById("dosCanvas")
    this.ctx = this.canvas.getContext("2d")
    this.width = this.canvas.width
    this.height = this.canvas.height

    // Spreadsheet state
    this.rows = 100
    this.cols = 26
    this.cellWidth = 80
    this.cellHeight = 20
    this.headerHeight = 20

    // Current selection
    this.selectedRow = 0
    this.selectedCol = 0
    this.editMode = false

    // Scroll position
    this.scrollX = 0
    this.scrollY = 0

    // Cell data storage
    this.cells = {}
    this.clipboard = null

    // Formula bar
    this.formulaInput = document.getElementById("formulaInput")
    this.cellRef = document.getElementById("cellRef")

    // Initialize
    this.setupInput()
    this.setupToolbar()
    this.render()

    console.log("[v0] Lotus 1-2-3 Engine initialized")
  }

  setupInput() {
    // Keyboard navigation
    document.addEventListener("keydown", (e) => {
      if (this.editMode && e.target === this.formulaInput) {
        if (e.key === "Enter") {
          e.preventDefault()
          this.confirmEdit()
        } else if (e.key === "Escape") {
          e.preventDefault()
          this.cancelEdit()
        }
        return
      }

      switch (e.key) {
        case "ArrowUp":
          e.preventDefault()
          this.moveSelection(0, -1)
          break
        case "ArrowDown":
          e.preventDefault()
          this.moveSelection(0, 1)
          break
        case "ArrowLeft":
          e.preventDefault()
          this.moveSelection(-1, 0)
          break
        case "ArrowRight":
          e.preventDefault()
          this.moveSelection(1, 0)
          break
        case "Tab":
          e.preventDefault()
          this.moveSelection(1, 0)
          break
        case "Enter":
          e.preventDefault()
          this.startEdit()
          break
        case "F2":
          e.preventDefault()
          this.startEdit()
          break
        case "Delete":
          e.preventDefault()
          this.clearCell()
          break
        case "c":
          if (e.ctrlKey || e.metaKey) {
            e.preventDefault()
            this.copyCell()
          }
          break
        case "v":
          if (e.ctrlKey || e.metaKey) {
            e.preventDefault()
            this.pasteCell()
          }
          break
      }
    })

    // Canvas click
    this.canvas.addEventListener("click", (e) => {
      const rect = this.canvas.getBoundingClientRect()
      const x = e.clientX - rect.left
      const y = e.clientY - rect.top

      if (y > this.headerHeight) {
        const col = Math.floor((x + this.scrollX) / this.cellWidth)
        const row = Math.floor((y - this.headerHeight + this.scrollY) / this.cellHeight)

        if (col >= 0 && col < this.cols && row >= 0 && row < this.rows) {
          this.selectedCol = col
          this.selectedRow = row
          this.updateFormulaBar()
          this.render()
        }
      }
    })

    // Canvas double-click for edit
    this.canvas.addEventListener("dblclick", () => {
      this.startEdit()
    })
  }

  setupToolbar() {
    document.getElementById("newBtn").addEventListener("click", () => {
      if (confirm("Create new spreadsheet? Unsaved changes will be lost.")) {
        this.cells = {}
        this.selectedRow = 0
        this.selectedCol = 0
        this.updateFormulaBar()
        this.render()
        this.showStatus("New spreadsheet created", "success")
      }
    })

    document.getElementById("saveBtn").addEventListener("click", () => {
      this.saveSpreadsheet()
    })

    document.getElementById("loadBtn").addEventListener("click", () => {
      this.loadSpreadsheet()
    })

    document.getElementById("boldBtn").addEventListener("click", () => {
      this.showStatus("Format not yet implemented", "error")
    })

    document.getElementById("italicBtn").addEventListener("click", () => {
      this.showStatus("Format not yet implemented", "error")
    })

    document.getElementById("formatSelect").addEventListener("change", (e) => {
      const format = e.target.value
      const cellKey = this.getCellKey(this.selectedRow, this.selectedCol)
      if (this.cells[cellKey]) {
        this.cells[cellKey].format = format
        this.render()
      }
    })
  }

  moveSelection(dx, dy) {
    this.selectedCol = Math.max(0, Math.min(this.cols - 1, this.selectedCol + dx))
    this.selectedRow = Math.max(0, Math.min(this.rows - 1, this.selectedRow + dy))
    this.updateFormulaBar()
    this.render()
  }

  startEdit() {
    this.editMode = true
    this.formulaInput.focus()
    this.formulaInput.select()
  }

  confirmEdit() {
    const value = this.formulaInput.value.trim()
    const cellKey = this.getCellKey(this.selectedRow, this.selectedCol)

    if (value === "") {
      delete this.cells[cellKey]
    } else {
      this.cells[cellKey] = {
        value: value,
        formula: value.startsWith("=") ? value : null,
        computed: this.computeValue(value),
        format: "general",
      }
    }

    this.editMode = false
    this.moveSelection(0, 1)
    this.render()
  }

  cancelEdit() {
    this.editMode = false
    this.updateFormulaBar()
    this.formulaInput.blur()
  }

  clearCell() {
    const cellKey = this.getCellKey(this.selectedRow, this.selectedCol)
    delete this.cells[cellKey]
    this.updateFormulaBar()
    this.render()
  }

  copyCell() {
    const cellKey = this.getCellKey(this.selectedRow, this.selectedCol)
    this.clipboard = this.cells[cellKey] ? { ...this.cells[cellKey] } : null
    this.showStatus("Cell copied", "success")
  }

  pasteCell() {
    if (this.clipboard) {
      const cellKey = this.getCellKey(this.selectedRow, this.selectedCol)
      this.cells[cellKey] = { ...this.clipboard }
      this.updateFormulaBar()
      this.render()
      this.showStatus("Cell pasted", "success")
    }
  }

  updateFormulaBar() {
    const cellRef = this.getColumnName(this.selectedCol) + (this.selectedRow + 1)
    this.cellRef.textContent = cellRef

    const cellKey = this.getCellKey(this.selectedRow, this.selectedCol)
    const cell = this.cells[cellKey]
    this.formulaInput.value = cell ? cell.value : ""
  }

  computeValue(value) {
    if (!value.startsWith("=")) {
      return value
    }

    try {
      // Simple formula evaluation (for demo purposes)
      const formula = value.substring(1)

      // Replace cell references with values (A1, B2, etc.)
      let evalFormula = formula.replace(/([A-Z]+)([0-9]+)/g, (match, col, row) => {
        const cellKey = this.getCellKey(Number.parseInt(row) - 1, this.getColumnIndex(col))
        const cell = this.cells[cellKey]
        return cell ? cell.computed : "0"
      })

      // Basic functions
      evalFormula = evalFormula.replace(/SUM$$([^)]+)$$/gi, (match, range) => {
        // Simple SUM implementation
        return "0"
      })

      // Evaluate
      const result = eval(evalFormula)
      return isNaN(result) ? "#ERROR" : result
    } catch (error) {
      return "#ERROR"
    }
  }

  getCellKey(row, col) {
    return `${col},${row}`
  }

  getColumnName(col) {
    return String.fromCharCode(65 + col)
  }

  getColumnIndex(name) {
    return name.charCodeAt(0) - 65
  }

  formatValue(value, format) {
    if (!value || value === "#ERROR") return value

    const num = Number.parseFloat(value)
    if (isNaN(num)) return value

    switch (format) {
      case "number":
        return num.toFixed(2)
      case "currency":
        return "$" + num.toFixed(2)
      case "percent":
        return (num * 100).toFixed(2) + "%"
      case "date":
        return new Date(num).toLocaleDateString()
      default:
        return value
    }
  }

  render() {
    // Clear canvas
    this.ctx.fillStyle = "#000000"
    this.ctx.fillRect(0, 0, this.width, this.height)

    // Draw column headers
    this.ctx.fillStyle = "#1e3a5f"
    this.ctx.fillRect(0, 0, this.width, this.headerHeight)

    this.ctx.fillStyle = "#ffffff"
    this.ctx.font = "12px Courier New"
    this.ctx.textAlign = "center"
    this.ctx.textBaseline = "middle"

    for (let col = 0; col < this.cols; col++) {
      const x = col * this.cellWidth - this.scrollX
      if (x > -this.cellWidth && x < this.width) {
        this.ctx.fillText(this.getColumnName(col), x + this.cellWidth / 2, this.headerHeight / 2)
      }
    }

    // Draw cells
    this.ctx.textAlign = "left"
    for (let row = 0; row < this.rows; row++) {
      const y = row * this.cellHeight + this.headerHeight - this.scrollY

      if (y > this.headerHeight - this.cellHeight && y < this.height) {
        // Row header
        this.ctx.fillStyle = "#1e3a5f"
        this.ctx.fillRect(0, y, this.cellWidth / 2, this.cellHeight)
        this.ctx.fillStyle = "#ffffff"
        this.ctx.fillText(String(row + 1), 5, y + this.cellHeight / 2)

        // Cells
        for (let col = 0; col < this.cols; col++) {
          const x = col * this.cellWidth - this.scrollX

          if (x > -this.cellWidth && x < this.width) {
            // Cell background
            const isSelected = row === this.selectedRow && col === this.selectedCol
            this.ctx.fillStyle = isSelected ? "#2d5a7b" : "#0a0a0a"
            this.ctx.fillRect(x, y, this.cellWidth, this.cellHeight)

            // Cell border
            this.ctx.strokeStyle = "#333333"
            this.ctx.strokeRect(x, y, this.cellWidth, this.cellHeight)

            // Cell value
            const cellKey = this.getCellKey(row, col)
            const cell = this.cells[cellKey]
            if (cell) {
              this.ctx.fillStyle = "#00ff00"
              const displayValue = this.formatValue(cell.computed, cell.format)
              this.ctx.fillText(displayValue, x + 4, y + this.cellHeight / 2)
            }

            // Selection highlight
            if (isSelected) {
              this.ctx.strokeStyle = "#4a90e2"
              this.ctx.lineWidth = 2
              this.ctx.strokeRect(x + 1, y + 1, this.cellWidth - 2, this.cellHeight - 2)
              this.ctx.lineWidth = 1
            }
          }
        }
      }
    }
  }

  async saveSpreadsheet() {
    try {
      const data = {
        cells: this.cells,
        timestamp: new Date().toISOString(),
      }

      if (window.FORGE_ENV && window.FORGE_ENV.isLocal) {
        // Local dev mode - use mock Forge API
        const response = await fetch(`${window.FORGE_ENV.apiBase}/saveSpreadsheet`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            macroId: window.FORGE_ENV.macroId,
            data: data,
          }),
        })

        const result = await response.json()
        if (result.success) {
          this.showStatus("Spreadsheet saved!", "success")
          console.log("[v0] Spreadsheet saved to dev server:", data)
        } else {
          throw new Error(result.message)
        }
      } else {
        // Fallback to localStorage for now
        localStorage.setItem("lotus123-data", JSON.stringify(data))
        this.showStatus("Spreadsheet saved!", "success")
        console.log("[v0] Spreadsheet saved to localStorage:", data)
      }
    } catch (error) {
      console.error("[v0] Save error:", error)
      this.showStatus("Save failed", "error")
    }
  }

  async loadSpreadsheet() {
    try {
      if (window.FORGE_ENV && window.FORGE_ENV.isLocal) {
        // Local dev mode - use mock Forge API
        const response = await fetch(`${window.FORGE_ENV.apiBase}/loadSpreadsheet`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            macroId: window.FORGE_ENV.macroId,
          }),
        })

        const result = await response.json()
        if (result.success && result.data) {
          this.cells = result.data.cells || {}
          this.updateFormulaBar()
          this.render()
          this.showStatus("Spreadsheet loaded!", "success")
          console.log("[v0] Spreadsheet loaded from dev server:", result.data)
        } else {
          this.showStatus("No saved data found", "error")
        }
      } else {
        // Fallback to localStorage for now
        const data = localStorage.getItem("lotus123-data")

        if (data) {
          const parsed = JSON.parse(data)
          this.cells = parsed.cells || {}
          this.updateFormulaBar()
          this.render()
          this.showStatus("Spreadsheet loaded!", "success")
          console.log("[v0] Spreadsheet loaded from localStorage:", parsed)
        } else {
          this.showStatus("No saved data found", "error")
        }
      }
    } catch (error) {
      console.error("[v0] Load error:", error)
      this.showStatus("Load failed", "error")
    }
  }

  showStatus(message, type) {
    const status = document.getElementById("status")
    status.textContent = message
    status.className = `status ${type}`
    setTimeout(() => {
      status.textContent = ""
      status.className = "status"
    }, 3000)
  }
}

// Initialize when DOM is ready
window.addEventListener("DOMContentLoaded", () => {
  const lotus = new LotusEngine()
})
