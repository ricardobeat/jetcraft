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

# Share HTTP server between Express and Socket.IO
server = http.createServer app
socketio.listen server

server.listen 8000
console.log "Express server listening on port %d", 8000