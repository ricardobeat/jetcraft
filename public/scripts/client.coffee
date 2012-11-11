
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

    console.log arr

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
        #if @iter is 2 then @stop()

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
            x = col * @blockSize | 0
            y = row * @blockSize | 0
            size = @blockSize
            if tile isnt currentBlockType
                currentBlockType = tile
                @ctx.fillStyle = switch tile
                    when 0  then '#eeeeff'
                    when 10 then '#66cc44'


            @ctx.fillRect x - @scrollX, y, size, size
        for p in @players
            size = @blockSize
            @ctx.fillStyle = '#ddd'
            @ctx.fillRect p.X - @scrollX, p.Y, size, size
            if p.myCharacter and p.X >= @canvas.width / 2 
                @scrollX = p.X - @canvas.width / 2
        return

    newPlayer: (player) =>
        @players.push player
        player.X = player.X*@blockSize | 0
        player.Y = player.Y*@blockSize | 0
        player.bindKeys() if player.myCharacter

Game = new GameEngine

# Player
# ------

class Player
    constructor:->
        @X = 0
        @Y = 0
        
        @speedX = 0
        @speedY = 0
        @gravity = 0
        @attrition = 0.7

        @defaultSpeed = 10
        @defaultGravity = 10

        @gravityLimit = 30
        @jumpLimit = 10

        @jumping = false
        @falling = false
        @movingLeft = false
        @movingRight = false
        @hasFloor = true
        @myCharacter = false

        @keysMap =
            65: @moveLeft
            68: @moveRight
            87: @jump
            37: @moveLeft
            39: @moveRight
            38: @jump
            32: @jump

    update: =>
        @X += @speedX | 0
        @Y += @speedY | 0

        if @movingright and not @movingleft
            @speedX += @defaultSpeed if @speedX <= @defaultSpeed

        if @movingleft and not @movingright
            @speedX -= @defaultSpeed if @speedX >= -@defaultSpeed
       
        if @jumping and !@falling and @speedY >= -@jumpLimit
            @speedY -= @jumpLimit / 2
        else if not @hasFloor
            @jumping = false
            @falling = true
        else
            @falling = false
            @gravity = 0 #shut down gravity if we have floor

        if @falling
            @speedY += @gravity if @speedY < @gravity*2

        if not @jumping and @speedX != 0
            @speedX = @speedX * @attrition

        #we have to set this false on each iteration or the player will not fall
        #@hasFloor = false

    bindKeys:=>
        km = @keysMap
        document.addEventListener 'keydown', (e) ->
            km[e.keyCode] true if km[e.keyCode]?
        document.addEventListener 'keyup', (e) ->
            km[e.keyCode] false if km[e.keyCode]?

    moveRight: (keydown) =>
        @movingright =  keydown

    moveLeft: (keydown) =>
        @movingleft = keydown
            
    jump: (keydown)=>
        @jumping = keydown
        if not keydown
            @gravity = @defaultGravity
            @falling = true 

player = new Player
player.myCharacter = true
player.X = 3
player.Y = 15
Game.newPlayer player

# Sockets
# -------
window.socket = io.connect()

socket.on 'world', (data) ->
    Game.map = expand data.map
    Game.run()

socket.on 'update', (data) ->
    console.log 'Update', data
    for block, type of data
        Game.map[block] = type
    Game.draw()

socket.emit 'loadWorld'

# Player controls
# ---------------

pixelToBlock = (x, y) ->
    col = Math.floor x / Game.blockSize
    row = Math.floor y / Game.blockSize
    return { col, row }

Game.canvas.addEventListener 'click', (e) ->
    coords = pixelToBlock e.pageX + Game.scrollX, e.pageY
    block = (coords.col * 30) + coords.row
    if Game.map[block] is TILES.air
        socket.emit 'put', block
        console.log "Adding block @#{coords}, #{block}"
    else
        socket.emit 'del', block
        console.log "Removing block @#{coords}, #{block}"
    