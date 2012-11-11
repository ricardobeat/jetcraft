# Dependencies
# ------------
fs = require 'fs'

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
  mapSize = 640 * 4000
  map = new Buffer mapSize
  map.fill TILES.air
  map.slice(Math.floor mapSize/2, mapSize).fill TILES.dirt

map[1] = TILES.dirt

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

module.exports =
  getmap: -> compact map, TILE_CODES