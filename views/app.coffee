# Dependencies
# ------------
express = require 'express'

# Express app
# -----------
app = express.createServer()

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
  app.listen 3000
  console.log "Express server listening on port %d", app.address().port

module.exports = app