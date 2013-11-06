CGMinerClient = require ('cgminer')
async = require('async')
_ = require('./underscore-plus')
db = require ('./db')

exports.initialize = ->
    setInterval(updateDevices, 30000)
    updateDevices()

CGMinerClient.prototype._devdetails = (r) ->
    r.DEVDETAILS

updateDevices = ->
    db.devices.distinct 'hostname', (err, hostnames) ->
        return if err
        for hostname in hostnames
            for port in [4028..4034]
                do (hostname, port) ->
                    client = new CGMinerClient({host: hostname, port: port})
                    async.parallel({
                        devs: (callback) ->
                            client.devs().then((results) ->
                                callback(null, results)
                            ,(err) ->
                                callback(err)
                            )
                        devdetails: (callback) ->
                            client.devdetails().then((results) ->
                                callback(null, results)
                            ,(err) ->
                                callback(err)
                            )
                    }, (err, results) ->
                        return if err
                        devs = _.toDictionary results.devs, (item) ->
                            return "gpu#{item.GPU}" if item.GPU?
                            "#{item.Name.toLowerCase()}#{item.ID}"
                        devdetails = _.toDictionary results.devdetails, (item) ->
                            "#{item.Name.toLowerCase()}#{item.ID}"
                        for key of devs
                            hw = devs[key]['Hardware Errors']
                            accepted = devs[key]['Difficulty Accepted']
                            rejected = devs[key]['Difficulty Rejected']
                            errors = 0
                            if hw and accepted? and rejected?
                                total = hw + accepted + rejected
                                errors = Number((100 * hw / total).toFixed(2)) if total > 0
                            status = devs[key]['Status']
                            temp = devs[key]['Temperature']
                            db.devices.update( {hostname: hostname, device: key}, {$set: {status: status, temp: temp, errors: errors}} )
                        console.log "updated cgminer stats for #{hostname}:#{port}"
                    )
