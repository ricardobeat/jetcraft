
# Trying to find a RequestAnimationFrame implementation.
window.RequestAnimationFrame ?=
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame    ||
    window.oRequestAnimationFrame      ||
    window.msRequestAnimationFrame

IMAGES =
    player: 'images/boneco.png'

for image, src of IMAGES
    img = new Image
    img.src = src
    IMAGES[image] = img

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
        @players = {}
        @playerTags = {}
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
        for name, player of @players
            player.update()
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

            # Skip off-screen tiles
            continue if x < @scrollX or x > @scrollX + Game.canvas.width + Game.blockSize

            ## Re-calculate lighting every 1s
            if @iter % 20 == 0 and tile is TILES.dirt
                light = 0
                for j in [i-2, i-1, i+29, i+30, i-30, i-31, i+1, i+2]
                    if @map[j] is TILES.air
                        light++
                tile = @map[i] = 10 + Math.ceil(light/2)

            if tile isnt currentBlockType
                currentBlockType = tile
                @ctx.fillStyle = switch tile
                    when 0  then '#eeeeff'
                    when 10 then '#22cc00'
                    when 11 then '#47cf27'
                    when 12 then '#66dd44'
                    when 13 then '#99dd66'
                    when 14 then '#aadf77'

            @ctx.fillRect x - @scrollX, y, size, size

        for name, p of @players
            @ctx.fillStyle = '#ddd'

            if p.speedX < 0
                if p.speedY isnt 0
                    sx = 10
                else
                    sx = 0
            else
                if p.speedY isnt 0
                    sx = 30
                else
                    sx = 20

            @ctx.drawImage IMAGES.player, sx, 0, 10, 20, p.x - @scrollX, p.y, p.width, p.height
            #@ctx.fillRect p.x - @scrollX, p.y, p.width, p.height
            nameTag = @playerTags[p.name]
            @ctx.drawImage nameTag, p.x - @scrollX - (nameTag.width/2) + (Game.blockSize/2), p.y - nameTag.height
            if p.own and p.x >= @canvas.width / 2 
                @scrollX = p.x - @canvas.width / 2
        return

    addPlayer: (player) =>
        @players[player.name] = player
        player.x *= @blockSize
        player.y *= @blockSize

        @prerenderTag player

    # Pre-render player name
    prerenderTag: (player) ->
        tempCanvas = document.createElement 'canvas'
        fontsize = 10
        buffer = 8
        tempCanvas.height = fontsize + buffer
        tempCanvas.width = 100
        tempCtx = tempCanvas.getContext '2d'
        tempCtx.font = '10px sans-serif'
        tempCtx.fillStyle = '#'+Math.floor(Math.random()*16777215/2).toString(16);
        tempCtx.textBaseline = 'top'
        tempCtx.textAlign = 'center'
        tempCtx.fillText player.name, tempCanvas.width/2, 0
        @playerTags[player.name] = tempCanvas

window.Game = new GameEngine

slowLog = (freq, msg) ->
    if Game.iter % freq == 0
        console.log msg

# Player
# ------

class Player
    constructor: (@name, @x = 0, @y = 0, @own) ->
        
        @width = Game.blockSize
        @height = Game.blockSize * 2

        @speedX = 0
        @speedY = 0

        @friction = 0.75
        @maxSpeed = 8
        @gravity = 0.8

        @jumping = false
        @falling = false
        @movingLeft = false
        @movingRight = false
        @hasFloor = true

    update: =>
        # Update position
        @x += @speedX
        @y += @speedY

        @x = 0 if @x <= 0
        @y = 0 if @y <= 0

        if @KEY_RIGHT
            @speedX = Math.min @speedX + 2, @maxSpeed

        if @KEY_LEFT
            @speedX = Math.min @speedX - 2, @maxSpeed

        if @KEY_JUMP
            @speedY = -5

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

playerName = window.localStorage?.name
if not playerName
    playerName = prompt 'My name is '
    window.localStorage?.name = playerName
PLAYER = new Player playerName, 3, 3, true
PLAYER.bindKeys()
Game.addPlayer PLAYER

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

socket.on 'newPlayer', (data) ->
    Game.addPlayer new Player data.name, -20, -20

socket.on 'playersList', (players) ->
    for name, p of players
        continue if Game.players[name]?
        Game.addPlayer new Player name, p.x, p.y

socket.on 'updatePlayer', (data) ->
    console.log data
    if (player = Game.players[data.name])
        console.log data
        player.x = data.x * Game.blockSize
        player.y = data.y * Game.blockSize

socket.emit 'setup', { name: PLAYER.name, size: Game.blockSize }

lx = ly = 0
setInterval ->
    x = Math.floor PLAYER.x
    y = Math.floor PLAYER.y
    socket.emit 'move', { x, y } unless lx == x and ly == y
    lx = x
    ly = y
, 1000/4

# Player controls
# ---------------

pixelToBlock = (x, y) ->
    col = Math.floor x / Game.blockSize
    row = Math.floor y / Game.blockSize
    return { col, row, index: col * 30 + row }

Game.canvas.addEventListener 'click', (e) ->
    x = e.pageX
    y = e.pageY

    distance = Math.sqrt Math.pow(x + Game.scrollX - PLAYER.x, 2) + Math.pow(y - PLAYER.y, 2)

    return if distance > Game.blockSize * 4

    coords = pixelToBlock x + Game.scrollX, y
    block = (coords.col * 30) + coords.row

    return if coords.col < 3

    if Game.map[block] is TILES.air
        socket.emit 'put', block
        console.log "Adding block @#{JSON.stringify coords}, #{block}"
    else
        socket.emit 'del', block
        console.log "Removing block @#{JSON.stringify coords}, #{block}"
    