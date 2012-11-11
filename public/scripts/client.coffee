
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

socket = io.connect()

socket.on 'world', (data) ->
    console.log data
    #console.log expand data.map