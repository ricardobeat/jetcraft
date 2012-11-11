
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

do -> window.requestAnimFrame = () ->
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