
# Trying to find a RequestAnimationFrame implementation.
window.RequestAnimationFrame ?=
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame    ||
    window.oRequestAnimationFrame      ||
    window.msRequestAnimationFrame

# Last resort.
unless window.requestAnimationFrame?
    window.requestAnimationFrame = (callback,element) ->
        setTimeout callback, 1000/60
    window.cancelAnimationFrame = (id) ->
        clearTimeout id

TILES =
  air  : 0
  dirt : 10

# Tile codes for inflating map data.
TILE_CODES =
    A: 0
    D: 10

# Our super-powerful de-compression algorithm.
expand = (arr) ->
    output = []

    arr.replace /\w\d+/g, (m) ->
        block_type = m[0]
        count = m.slice(1)
        while count--
            output.push TILE_CODES[block_type]

    return output

# Game engine
# -----------

class GameEngine

    constructor: (root = document.body) ->
        @createCanvas root
        @iter = 0
        @players = []
        @scrollX = 0

    createCanvas: (root) ->
        @canvas = document.createElement 'canvas'
        w = document.body.clientWidth or window.innerWidth
        h = Math.min w * 0.75, document.body.clientHeight or window.innerHeight
        console.log "Width: #{w}, Height: #{h}"
        @canvas.width = w
        @canvas.height = h
        @ctx = @canvas.getContext '2d'
        root.appendChild @canvas
        @calculateSizes()

    calculateSizes: ->
        @blockSize = Math.ceil @canvas.height / 30
        console.log "Blocks are #{@blockSize}px wide"

    run: =>
        @iter++
        @animation_id = requestAnimationFrame @run
        @update()
        @draw()
        return

    stop: =>
        cancelAnimationFrame @animation_id

    update: ->
        for p in @players
            p.update()
        return

    draw: ->
        currentBlockType = null

        for tile, i in @map
            col  = Math.floor i / 30
            row = i % 30
            # Draw blocks like a grid
            size = @blockSize
            x = col * size
            y = row * size
            if tile isnt currentBlockType
                currentBlockType = tile
                @ctx.fillStyle = switch tile
                    when 0  then '#eeeeff'
                    when 10 then '#66cc44'

            @ctx.fillRect x - @scrollX, y, size, size

        for p in @players
            @ctx.fillStyle = '#ddd'
            @ctx.fillRect p.x - @scrollX, p.y, p.width, p.height
            if p.own and p.x >= @canvas.width / 2 
                @scrollX = p.x - @canvas.width / 2
        return

    addPlayer: (player) =>
        @players.push player
        player.X = player.X * @blockSize | 0
        player.Y = player.Y * @blockSize | 0

Game = new GameEngine

slowLog = (freq, msg) ->
    if Game.iter % freq == 0
        console.log msg

# Player
# ------

class Player
    constructor: (@x = 0, @y = 0, @own) ->
        
        @width = Game.blockSize
        @height = Game.blockSize * 2

        @speedX = 0
        @speedY = 0

        @friction = 0.7
        @maxSpeed = 10
        @gravity = 2

        @jumping = false
        @falling = false
        @movingLeft = false
        @movingRight = false
        @hasFloor = true

    update: =>
        # Update position
        @x += @speedX
        @y += @speedY

        if @KEY_RIGHT
            @speedX = Math.min @speedX + 5, @maxSpeed

        if @KEY_LEFT
            @speedX = Math.min @speedX - 5, @maxSpeed

        @applyPhysics()

    getSensors: ->
        return {
            top    : [@x + Math.floor(@width/2), @y - 1]
            right  : [@x + @width + 1, @y + Math.floor(@height/2)]
            bottom : [@x + Math.floor(@width/2), @y + @height + 1]
            left   : [@x - 1, @y + Math.floor(@height/2)]
        }

    detect: (sensor) ->
        return (pixelToBlock.apply null, sensor).index

    applyPhysics: ->

        sensors = @getSensors()

        pos = pixelToBlock @x, @y + @height
        currentBlock = pos.col * 30 + pos.row

        if @falling
            @speedY += @gravity

        # Check for a tile underneath. If found,
        # snap player position to the top of it
        if Game.map[@detect sensors.bottom] isnt TILES.air
            if @falling
                @speedY = 0
                @y -= @y % Game.blockSize
                @falling = false
        else
            @falling = true

        # Lateral collisions
        left  = Game.map[@detect sensors.left]
        right = Game.map[@detect sensors.right]

        if right? and @speedX > 0 and right isnt TILES.air
            @speedX = 0

        if left? and @speedX < 0 and left isnt TILES.air
            @speedX = 0

        # Friction
        if not @jumping and @speedX isnt 0
            @speedX *= @friction
            @speedX = 0 if Math.abs(@speedX) < 0.5

        return

        if @jumping
            if(!@falling && @speedY >= -@jumpLimit)
                @speedY -= @jumpLimit / 2
            else
                @jumping = false
                @falling = true

        if not @hasFloor
            @falling = true
        else
            @falling = false
            @gravity = 0 #shut down gravity if we have floor

        if @falling
            @speedY += @gravity if @speedY < @gravity*2

        if not @jumping and @speedX != 0
            @speedX = @speedX * @attrition

        return

    bindKeys: ->
        document.addEventListener 'keydown', (e) =>
            e.preventDefault()
            @keyPress e.keyCode, true

        document.addEventListener 'keyup', (e) =>
            e.preventDefault()
            @keyPress e.keyCode, false

        return

    keyPress: (keyCode, state) ->
        switch keyCode
            when 37, 65
                @KEY_LEFT = state
            when 39, 68
                @KEY_RIGHT = state
            when 32, 38, 87
                @KEY_JUMP = state 
        return

player = new Player 3, 15, true
player.bindKeys()
Game.addPlayer player

# Sockets
# -------
window.socket = io.connect()

socket.on 'world', (data) ->
    console.log 'Loading map...'
    Game.map = expand data.map
    Game.run()

socket.on 'update', (data) ->
    for block, type of data
        Game.map[block] = type
    Game.draw()

socket.emit 'loadWorld'

# Player controls
# ---------------

pixelToBlock = (x, y) ->
    col = Math.floor x / Game.blockSize
    row = Math.floor y / Game.blockSize
    return { col, row, index: col * 30 + row }

Game.canvas.addEventListener 'click', (e) ->
    coords = pixelToBlock e.pageX + Game.scrollX, e.pageY
    block = (coords.col * 30) + coords.row
    if Game.map[block] is TILES.air
        socket.emit 'put', block
        console.log "Adding block @#{coords}, #{block}"
    else
        socket.emit 'del', block
        console.log "Removing block @#{coords}, #{block}"
    