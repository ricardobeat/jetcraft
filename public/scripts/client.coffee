
socket = io.connect()

socket.on 'world', (map) ->
    console.log map