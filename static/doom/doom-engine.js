// Simplified DOOM-style game engine
class DoomEngine {
  constructor() {
    this.canvas = document.getElementById("gameCanvas")
    this.ctx = this.canvas.getContext("2d")
    this.width = this.canvas.width
    this.height = this.canvas.height

    // Player properties
    this.player = {
      x: 8,
      y: 8,
      angle: 0,
      speed: 0.08,
      rotSpeed: 0.05,
      health: 100,
      weapon: 1,
      ammo: 50,
    }

    // Game state
    this.running = false
    this.paused = false
    this.enemies = []
    this.projectiles = []
    this.lastTime = 0
    this.fps = 0

    // Raycasting properties
    this.fov = Math.PI / 3
    this.numRays = 320
    this.maxDepth = 20

    // Map (1 = wall, 0 = empty, 2 = door, 3 = enemy spawn)
    this.map = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 1],
      [1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1],
      [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
      [1, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 3, 0, 0, 1, 1, 2, 1, 1, 0, 0, 0, 3, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
      [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
      [1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ]

    // Input handling
    this.keys = {}
    this.setupInput()

    // Initialize enemies
    this.initEnemies()
  }

  initEnemies() {
    for (let y = 0; y < this.map.length; y++) {
      for (let x = 0; x < this.map[y].length; x++) {
        if (this.map[y][x] === 3) {
          this.enemies.push({
            x: x + 0.5,
            y: y + 0.5,
            health: 100,
            state: "idle",
            lastShot: 0,
          })
          this.map[y][x] = 0 // Clear spawn point
        }
      }
    }
  }

  setupInput() {
    document.addEventListener("keydown", (e) => {
      this.keys[e.key.toLowerCase()] = true

      // Weapon selection
      if (e.key >= "1" && e.key <= "7") {
        this.player.weapon = Number.parseInt(e.key)
      }

      // Shooting
      if (e.key === " ") {
        e.preventDefault()
        this.shoot()
      }
    })

    document.addEventListener("keyup", (e) => {
      this.keys[e.key.toLowerCase()] = false
    })
  }

  shoot() {
    if (this.player.ammo <= 0) return

    this.player.ammo--

    // Create projectile
    this.projectiles.push({
      x: this.player.x,
      y: this.player.y,
      angle: this.player.angle,
      speed: 0.3,
      damage: 25,
      lifetime: 100,
    })

    // Check for hits
    const ray = this.castRay(this.player.angle)
    if (ray.enemy) {
      ray.enemy.health -= 25
      if (ray.enemy.health <= 0) {
        const idx = this.enemies.indexOf(ray.enemy)
        if (idx > -1) {
          this.enemies.splice(idx, 1)
        }
      }
    }
  }

  start() {
    if (!this.running) {
      this.running = true
      this.paused = false
      this.lastTime = performance.now()
      this.gameLoop()
    }
  }

  togglePause() {
    this.paused = !this.paused
    if (!this.paused && this.running) {
      this.lastTime = performance.now()
      this.gameLoop()
    }
  }

  reset() {
    this.player.x = 8
    this.player.y = 8
    this.player.angle = 0
    this.player.health = 100
    this.player.ammo = 50
    this.enemies = []
    this.projectiles = []
    this.initEnemies()
  }

  gameLoop() {
    if (!this.running || this.paused) return

    const currentTime = performance.now()
    const deltaTime = (currentTime - this.lastTime) / 16.67 // Normalize to 60fps
    this.lastTime = currentTime

    // Calculate FPS
    this.fps = Math.round(1000 / (currentTime - (this.lastFrameTime || currentTime)))
    this.lastFrameTime = currentTime
    document.getElementById("fps").textContent = `FPS: ${this.fps}`

    this.update(deltaTime)
    this.render()

    requestAnimationFrame(() => this.gameLoop())
  }

  update(deltaTime) {
    // Player movement
    const moveSpeed = this.player.speed * deltaTime
    const rotSpeed = this.player.rotSpeed * deltaTime

    if (this.keys["arrowup"] || this.keys["w"]) {
      const newX = this.player.x + Math.cos(this.player.angle) * moveSpeed
      const newY = this.player.y + Math.sin(this.player.angle) * moveSpeed
      if (this.isWalkable(newX, newY)) {
        this.player.x = newX
        this.player.y = newY
      }
    }

    if (this.keys["arrowdown"] || this.keys["s"]) {
      const newX = this.player.x - Math.cos(this.player.angle) * moveSpeed
      const newY = this.player.y - Math.sin(this.player.angle) * moveSpeed
      if (this.isWalkable(newX, newY)) {
        this.player.x = newX
        this.player.y = newY
      }
    }

    if (this.keys["arrowleft"] || this.keys["a"]) {
      this.player.angle -= rotSpeed
    }

    if (this.keys["arrowright"] || this.keys["d"]) {
      this.player.angle += rotSpeed
    }

    // Update projectiles
    for (let i = this.projectiles.length - 1; i >= 0; i--) {
      const proj = this.projectiles[i]
      proj.x += Math.cos(proj.angle) * proj.speed * deltaTime
      proj.y += Math.sin(proj.angle) * proj.speed * deltaTime
      proj.lifetime--

      if (proj.lifetime <= 0 || !this.isWalkable(proj.x, proj.y)) {
        this.projectiles.splice(i, 1)
      }
    }

    // Update enemies
    for (const enemy of this.enemies) {
      const dx = this.player.x - enemy.x
      const dy = this.player.y - enemy.y
      const dist = Math.sqrt(dx * dx + dy * dy)

      if (dist < 8) {
        enemy.state = "alert"

        // Move towards player
        const angle = Math.atan2(dy, dx)
        const moveX = enemy.x + Math.cos(angle) * 0.02 * deltaTime
        const moveY = enemy.y + Math.sin(angle) * 0.02 * deltaTime

        if (this.isWalkable(moveX, moveY)) {
          enemy.x = moveX
          enemy.y = moveY
        }
      }
    }
  }

  isWalkable(x, y) {
    const mapX = Math.floor(x)
    const mapY = Math.floor(y)

    if (mapX < 0 || mapX >= this.map[0].length || mapY < 0 || mapY >= this.map.length) {
      return false
    }

    return this.map[mapY][mapX] === 0
  }

  castRay(angle) {
    const cos = Math.cos(angle)
    const sin = Math.sin(angle)
    let distance = 0
    let hitWall = false
    let hitEnemy = null

    while (!hitWall && distance < this.maxDepth) {
      distance += 0.1
      const testX = this.player.x + cos * distance
      const testY = this.player.y + sin * distance

      // Check enemies first
      for (const enemy of this.enemies) {
        const dx = enemy.x - testX
        const dy = enemy.y - testY
        if (Math.sqrt(dx * dx + dy * dy) < 0.3) {
          hitEnemy = enemy
          hitWall = true
          break
        }
      }

      if (!hitWall) {
        const mapX = Math.floor(testX)
        const mapY = Math.floor(testY)

        if (mapX < 0 || mapX >= this.map[0].length || mapY < 0 || mapY >= this.map.length) {
          hitWall = true
        } else if (this.map[mapY][mapX] !== 0) {
          hitWall = true
        }
      }
    }

    return { distance, enemy: hitEnemy }
  }

  render() {
    // Clear screen - draw floor and ceiling
    this.ctx.fillStyle = "#333"
    this.ctx.fillRect(0, 0, this.width, this.height / 2)
    this.ctx.fillStyle = "#666"
    this.ctx.fillRect(0, this.height / 2, this.width, this.height / 2)

    // Cast rays and render walls
    for (let i = 0; i < this.numRays; i++) {
      const rayAngle = this.player.angle - this.fov / 2 + (this.fov * i) / this.numRays
      const ray = this.castRay(rayAngle)

      // Fix fish-eye effect
      const correctedDist = ray.distance * Math.cos(rayAngle - this.player.angle)

      // Calculate wall height
      const wallHeight = (this.height / correctedDist) * 0.5

      // Calculate color based on distance and whether it's an enemy
      let brightness
      if (ray.enemy) {
        brightness = Math.max(0, 255 - correctedDist * 30)
        this.ctx.fillStyle = `rgb(${brightness}, 0, 0)`
      } else {
        brightness = Math.max(0, 255 - correctedDist * 20)
        this.ctx.fillStyle = `rgb(${brightness}, ${brightness}, ${brightness})`
      }

      // Draw wall slice
      const x = (i / this.numRays) * this.width
      const y = (this.height - wallHeight) / 2
      this.ctx.fillRect(x, y, this.width / this.numRays + 1, wallHeight)
    }

    // Draw HUD
    this.drawHUD()
  }

  drawHUD() {
    // Health bar
    this.ctx.fillStyle = "rgba(0, 0, 0, 0.5)"
    this.ctx.fillRect(10, this.height - 40, 200, 30)

    this.ctx.fillStyle = this.player.health > 50 ? "#0f0" : this.player.health > 25 ? "#ff0" : "#f00"
    this.ctx.fillRect(15, this.height - 35, this.player.health * 1.9, 20)

    this.ctx.fillStyle = "#fff"
    this.ctx.font = "14px Courier New"
    this.ctx.fillText(`Health: ${this.player.health}`, 20, this.height - 20)

    // Ammo
    this.ctx.fillStyle = "rgba(0, 0, 0, 0.5)"
    this.ctx.fillRect(this.width - 210, this.height - 40, 200, 30)

    this.ctx.fillStyle = "#ff0"
    this.ctx.fillText(`Ammo: ${this.player.ammo}`, this.width - 200, this.height - 20)

    // Weapon
    this.ctx.fillText(`Weapon: ${this.player.weapon}`, this.width - 200, this.height - 5)

    // Crosshair
    this.ctx.fillStyle = "#0f0"
    this.ctx.fillRect(this.width / 2 - 10, this.height / 2, 20, 2)
    this.ctx.fillRect(this.width / 2, this.height / 2 - 10, 2, 20)

    // Enemy count
    this.ctx.fillStyle = "rgba(0, 0, 0, 0.5)"
    this.ctx.fillRect(10, 10, 200, 30)

    this.ctx.fillStyle = "#f00"
    this.ctx.fillText(`Enemies: ${this.enemies.length}`, 20, 30)
  }
}

// Initialize game
const game = new DoomEngine()
console.log("[v0] DOOM Engine initialized")

// Auto-start the game
game.start()
