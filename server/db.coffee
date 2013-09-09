config = require('config')
MongoClient = require('mongodb').MongoClient

exports.initialize = (callback) ->
    MongoClient.connect "#{config.mongoDbConnectionString}?maxPoolSize=10&w=0", (err, db) ->
        if err
            callback(err)
            return
        console.log "Connected to MongoDB"
        exports.shares = db.collection('shares')
        exports.devices = db.collection('devices')
        exports.pools = db.collection('pools')
        exports.savings = db.collection('savings')
        exports.addresses = db.collection('addresses')

        exports.shares.ensureIndex {timestamp: 1}
        exports.shares.ensureIndex {pool: 1}

        callback()


