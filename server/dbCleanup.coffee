moment = require('moment')
db = require ('./db')

exports.initialize = ->
    setInterval(cleanUp, 300000)
    cleanUp()

cleanUp = ->
    cutoff = moment().subtract('days',3).subtract('hours',1).unix()
    db.shares.remove {timestamp: $lt: cutoff}, {w:1}, (err, count) ->
        return if err
        console.log "Removed #{count} shares older than #{moment.unix(cutoff).format('lll')}"

