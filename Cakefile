flour = require 'flour'
fs    = require 'fs'

task 'build:less', ->
    bundle 'public/styles/*.less', 'public/styles/base.css'

task 'build:coffee', ->
    compile 'public/scripts/client.coffee', 'public/scripts/client.js'

task 'build:shared', ->
    # Shared between server & client
    compile 'lib/tiles.coffee', 'public/scripts/tiles.js'
    flour.minifiers.js = null
    bundle [
        'node_modules/numpack/lib/numpack.js'
        'lib/tiles.coffee'
    ], 'public/scripts/shared.js'

task 'build', ->
    invoke 'build:less'
    invoke 'build:coffee'
    invoke 'build:shared'

task 'watch', ->

    # disable minifier
    flour.minifiers['.js'] = null

    invoke 'build'

    watch 'public/styles/*.less', ->
        invoke 'build:less'

    watch 'public/scripts/*.coffee', ->
        invoke 'build:coffee'

