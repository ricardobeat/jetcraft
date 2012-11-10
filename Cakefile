flour = require 'flour'

task 'build:less', ->
    

task 'build:coffee', ->
    compile 'public/scripts/client.coffee', 'public/scripts/client.js'

task 'build', ->
    invoke 'build:less'
    invoke 'build:coffee'

task 'watch', ->

    # disable minifier
    flour.minifiers['.js'] = null

    invoke 'build'

    watch 'public/styles/*.less', ->
        invoke 'build:less'

    watch 'public/scripts/*.coffee', ->
        invoke 'build:coffee'

