# Dependencies
# ------------
{Buffer} = require 'buffer'
express  = require 'express'
zlib     = require 'zlib'
http     = require 'http'
fs       = require 'fs'
cons     = require 'consolidate'
socketio = require 'socket.io'

# Express app
# -----------
app = express()

app.configure ->
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'html'
  app.engine 'html', cons.underscore
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static "#{__dirname}/public"
  
app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  res.render 'index', {}

# Share HTTP server between Express and Socket.IO
server = http.createServer app
io = socketio.listen server
io.set 'log level', 2

server.listen 8000
console.log "Express server listening on port %d", 8000

# Game server
# -----------
matrix = require './lib/matrix'

# Sockets
# -------

players = {}
playerIds = {}

io.sockets.on 'connection', (socket) ->

  # Send full map to client on connection
  socket.on 'setup', (name) ->
    socket.emit 'world', { map: matrix.getMap() }
    socket.emit 'playersList', players
    socket.broadcast.emit 'newPlayer', { name }
    players[name] = { name: name, x: 0, y: 0 }
    playerIds[socket.id] = name
    console.log name

  socket.on 'put', (block) ->
    matrix.put block

  socket.on 'del', (block) ->
    matrix.del block

  socket.on 'move', (pos) ->
    name = playerIds[socket.id]
    socket.broadcast.emit 'updatePlayer', { name , x: pos.x, y: pos.y }
    players[name].x = pos.x
    players[name].y = pos.y

matrix.on 'change', (data) ->
  io.sockets.emit 'update', data
