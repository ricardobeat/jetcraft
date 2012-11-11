# Dependencies
# ------------
fs = require 'fs'
_  = require 'underscore'
{EventEmitter} = require 'events'

# Tile types
TILES =
  air  : 0
  dirt : 10

TILE_CODES =
  0  : 'A'
  10 : 'D'

# Load map file, create a new map if it doesn't exist
if fs.existsSync 'world.dat'
  map = fs.readFileSync 'world.dat'
else
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

# Compress map data.
# Gets us around n_blocks + 3000 bytes (2560000 -> 13790 for 10.000 blocks)
#zipped = zlib.gzip map.toString('utf8'), (err, res) ->
#  console.log res.toString('hex')

compact = (arr, codes) ->

  current = null
  count   = 0
  output  = ''

  for item in arr
    item_code = codes[item]
    if item_code is current
      count++
    else
      if count > 0
        output += current + count
      current = item_code
      count = 1

  return output

# Expose API
matrix = new EventEmitter

_.extend matrix, 
  getMap: -> compact map, TILE_CODES
  put: -> matrix.emit 'change', { test: 1 }

# Test for server updates
floating_rows = (Math.floor Math.random() * 100 for i in [0..50])

setInterval ->
  row = floating_rows[Math.floor Math.random() * floating_rows.length]
  cur = row * 30
  limit = cur + 30
  while map[cur] isnt TILES.dirt and cur < limit
    cur += 1

  changes = {}

  if map[cur] is TILES.dirt
    changes[cur]   = map[cur]   = TILES.air
    changes[cur-1] = map[cur-1] = TILES.dirt

    matrix.emit 'change', changes
, 60

module.exports = matrix
