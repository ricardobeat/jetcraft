# Dependencies
# ------------
{Buffer} = require 'buffer'
express  = require 'express'
zlib     = require 'zlib'
fs       = require 'fs'
socketio = require 'socket.io'

# Express app
# -----------
app = express()

app.configure ->
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'kiwi'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static "#{__dirname}/public"
  
app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
  app.use express.errorHandler()

app.get '/', (req, res) ->

# Start server
unless module.parent
  app.listen 8000
  console.log "Express server listening on port %d", 8000

module.exports = app
###

# Tile types
TILES =
  air  : 0
  dirt : 10

# Load map file, create a new map if it doesn't exist
if fs.existsSync 'world.dat'
  map = fs.readFileSync 'world.dat'
else
  map = new Buffer 640 * 4000
  map.fill TILES.air

map[1] = TILES.dirt

# Compress map data.
# Gets us around n_blocks + 3000 bytes (2560000 -> 13790 for 10.000 blocks)
zipped = zlib.gzip map, (err, res) ->
  console.log res.length

