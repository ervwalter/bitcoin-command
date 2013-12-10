request = require('request-json')
async = require('async')
config = require('config')
BitcoinClient = require('bitcoin').Client

run = (pool, callback) ->
	client = request.newClient 'http://eligius.st/'
	bitcoin = new BitcoinClient config.bitcoin

	async.parallel({
		poolSize: (callback) ->
			client.get "/~luke-jr/raw/7/cppsrb.json", (err, r, body) ->
				if err
					callback err
					return
				try
					poolSize = Number(body[''].shares['256']) * 16777216 / 1000000
					callback(null, poolSize)
				catch e
					callback(e)
		balances: (callback) ->
			client.get "/~luke-jr/raw/7/balances.json", (err, r, body) ->
				if err
					callback err
					return
				try
					balances = {
						paid: body[pool.apiKey].everpaid / 100000000
						pending: body[pool.apiKey].balance / 100000000
					}
					callback(null, balances)
				catch e
					callback(e)
	}, (err, data) ->
		return if err
		callback { pending: data.balances.pending, payouts: data.balances.paid, poolSize: data.poolSize }
	)

exports.initialize = (clients) ->
	clients.eligius = run
