
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
        if @iter is 2 then @stop()

    stop: =>
        cancelAnimationFrame @animation_id

    update: ->

    draw: ->
        currentBlockType = null
        for tile, i in @map
            col  = Math.floor i / 30
            row = i % 30
            # Draw blocks like a grid
            x = col * @blockSize
            y = row * @blockSize
            size = @blockSize
            if tile isnt currentBlockType
                currentBlockType = tile
                @ctx.fillStyle = switch tile
                    when 0  then '#eeeeff'
                    when 10 then '#66cc44'


            @ctx.fillRect x, y, size, size
        return

Game = new GameEngine

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
    coords = pixelToBlock e.pageX, e.pageY
    block = (coords.col * 30) + coords.row
    if Game.map[block] is TILES.air
        socket.emit 'put', block
        console.log 'Adding block @#{coords}, #{block}'
    else
        socket.emit 'del', block
        console.log 'Removing block @#{coords}, #{block}'
    