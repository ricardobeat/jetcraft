tiles =
    air  : 0
    dirt : 10

if module.exports?
    module.exports = tiles
else
    window.TILES = tiles