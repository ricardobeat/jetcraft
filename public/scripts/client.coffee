
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

# Sockets
# -------
window.socket = io.connect()

socket.on 'world', (data) ->
    console.log data
    #console.log expand data.map

socket.on 'update', (data) ->
    console.log data

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

    run: =>
        @iter++
        @animation_id = requestAnimationFrame Game.run
        @update()
        @draw()
        if @iter is 2 then @stop()

    stop: =>
        cancelAnimationFrame @animation_id

    update: ->
        console.log 'Update', @iter

    draw: ->
        console.log 'Draw', @iter

Game = new GameEngine

window.addEventListener 'load', Game.run

