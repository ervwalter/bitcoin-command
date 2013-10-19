request = require('request-json')
async = require('async')
config = require('config')
BitcoinClient = require('bitcoin').Client

run = (pool, callback) ->
	client = request.newClient 'https://mining.bitcoin.cz/'
	bitcoin = new BitcoinClient config.bitcoin

	async.parallel({
		poolSize: (callback) ->
			client.get "/stats/json/#{pool.apiKey}", (err, r, body) ->
				if err
					callback err
					return
				try
					poolSize = Number(body.ghashes_ps) * 1000
					callback(null, poolSize)
				catch e
					callback(e)
		pending: (callback) ->
			client.get "/accounts/profile/json/#{pool.apiKey}", (err, r, body) ->
				if err
					callback err
					return
				try
					callback(null, Number(body.confirmed_reward) + Number(body.unconfirmed_reward))
				catch e
					callback(e)
		paid: (callback) ->
			if pool.payoutAddress?
				bitcoin.getReceivedByAddress pool.payoutAddress, callback
			else
				callback null, ''
	}, (err, data) ->
		return if err
		callback { pending: data.pending, payouts: data.paid, poolSize: data.poolSize }
	)

exports.initialize = (clients) ->
	clients.slush = run
