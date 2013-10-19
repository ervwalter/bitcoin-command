path = require('path')
db = require('./db')

exports.initialize = ->
	updatePools()
	setInterval updatePools, 300000

poolClients = {}

require("fs").readdirSync(path.join(__dirname, 'pools')).forEach (file) ->
	require("./pools/" + file).initialize(poolClients);

updatePools = ->
	db.pools.find(enabled: true).toArray (err, pools) ->
		return if err
		for pool in pools
			if pool.apiType
				do (pool) ->
					poolClients[pool.apiType]?(pool, (updates) ->
						if updates
							console.log "updated pool stats for #{pool.name}"
							db.pools.update {url: pool.url}, {$set: updates}
					)
		return
	return


