# Dependencies
# ------------
fs      = require 'fs'
_       = require 'underscore'
util    = require 'util'
numpack = require 'numpack'
events  = require 'events'

TILES = require './tiles'

# Map data
# --------

# Load map file, returns a Buffer object
loadMap = (path) ->
    try
        map = fs.readFileSync path
        console.log 'Loaded world.dat from disk'
    catch e
        map = false

    return map

# Generate a new map
generateMap = ->
    mapSize = 30 * 600
    map = new Buffer mapSize
    map.fill TILES.air

    floor_height = 20
    for i in [0..600-30]
        pos = 30*i

        floor_height = floor_height + (-1 + Math.round Math.random() * 2)
        if floor_height < 10
            floor_height += 2
        else if floor_height > 20
            floor_height -= 2

    map.slice(pos+floor_height, pos+30).fill TILES.dirt    
    console.log 'Generated new map'

    return map

# Save map to disk
saveMap = (map, path) ->
    fs.writeFile path, map, (err) ->
        console.log "Map saved to #{path} #{new Date}"


# Updates
# -------
changes = {}

changeBlock = (block, type) ->
    changes[block] = matrix.map[block] = type

# Bundle map updates in a single message
sendUpdates = ->
    if Object.keys(changes).length > 0
        matrix.emit 'change', changes
        changes = {}


# API
# ---
# Inherit from EventEmitter. This way we can
# receive and broadcast map events without
# interacting directly with the networking library
matrix = Object.create(events.EventEmitter.prototype)

_.extend matrix,
    init: (options) ->
        @map = loadMap(options.map) ? generateMap()

        # Save map every 15 seconds
        setInterval =>
            saveMap @map, options.map
        , 1000 * 15

        # Broadcast updates at 3 fps
        setInterval sendUpdates, 1000 / 3

    getMap: ->
        numpack.compact @map

    put: (block) ->
        changeBlock block, TILES.dirt

    del: (block) ->
        changeBlock block, TILES.air

module.exports = matrix
