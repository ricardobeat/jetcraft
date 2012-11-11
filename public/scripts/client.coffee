
TILE_CODES =
    A: 0
    D: 10

expand = (arr) ->
    output = []

    console.log arr

    arr.replace /\w\d+/g, (m) ->
        block_type = m[0]
        count = m.slice(1)
        while count--
            output.push TILE_CODES[block_type]

    return output

window.socket = io.connect()

socket.on 'world', (data) ->
    console.log data
    #console.log expand data.map

socket.on 'update', (data) ->
    console.log data

## New crap, needs refactor... coding here just for testing purposes. Don't freak out plz! :)

#requestAnimationFrame Polyfill
do -> window.requestAnimFrame = ->
    return window.RequestAnimationFrame ||
    window.webkitRequestAnimationFrame  ||
    window.mozRequestAnimationFrame     ||
    window.oRequestAnimationFrame       ||
    window.msRequestAnimationFrame      ||
    (callback,element)->
        window.setTimeout callback, 1000 / 60

if !window.requestAnimationFrame
    window.requestAnimationFrame = (callback, element) ->
        currTime = new Date().getTime()
        timeToCall = Math.max 0, 16 - (currTime - lastTime)
        id = window.setTimeout ()->
            callback currTime + timeToCall
        , timeToCall
        lastTime = currTime + timeToCall;
        return id
 
if !window.cancelAnimationFrame
  window.cancelAnimationFrame = (id) ->
    clearTimeout id

#canvas init
do ->
    canvas = document.createElement 'canvas'
    canvas.width = 800
    canvas.height = 600
    context = canvas.getContext '2d'
    document.body.appendChild canvas
    run()

run =>
    requestAnimFrame run
    update()
    draw()

update =>
    console.log "foo"

draw =>
    console.log "bar"