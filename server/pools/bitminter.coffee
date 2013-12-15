async = require('async')
config = require('config')
request = require('request-json')
BitcoinClient = require('bitcoin').Client

run = (pool, callback) ->
	client = request.newClient 'https://bitminter.com/'
	bitcoin = new BitcoinClient config.bitcoin

	async.parallel({
		poolSize: (callback) ->
			client.get "/api/pool/stats", (err, r, data) ->
				if err
					callback err
					return
				try
					poolSize = Number(data.hash_rate)
					callback(null, poolSize)
				catch e
					callback(e)
		pending: (callback) ->
			client.get "/api/users?key=#{pool.apiKey}", (err, r, data) ->
				if err
					callback err
					return
				try
					callback(null, Number(data.balances.BTC))
				catch e
					callback(e)
		paid: (callback) ->
			if pool.payoutAddress?
				bitcoin.getReceivedByAddress pool.payoutAddress, callback
			else
				callback null, ''
	}, (err, data) ->
		return if err
		console.log data
		callback { pending: data.pending, payouts: data.paid, poolSize: data.poolSize }
	)


exports.initialize = (clients) ->
	clients.bitminter = run

