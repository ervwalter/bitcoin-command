config = require('config')
async = require('async')
BitcoinClient = require('bitcoin').Client
moment = require('moment')
request = require('request-json')
url = require('url')

_ = require('./underscore-plus')
db = require('./db')

defaultNumberOfTransactions = 50

getAddressPreferences = (callback) ->
	db.addresses.find().toArray (err, addresses) ->
		if err
			callback(err)
			return
		preferences = _.toDictionary addresses, (a) -> a.address
		callback(null, preferences)
		return
	return

exports.summary = (req, res) ->
	client = new BitcoinClient config.bitcoin

	show = req.query.show
	show = 1000000 if show is 'all'
	show = Number(show)
	show = defaultNumberOfTransactions if isNaN(show) or show < 1

	async.parallel({
		preferences: (callback) ->
			getAddressPreferences(callback)
		balance: (callback) ->
			client.getBalance callback
		transactions: (callback) ->
			client.listTransactions '*', Math.max(show + 1, 100), callback
		pools: (callback) ->
			db.pools.find({}, {name: 1, payoutAliases: 1}).toArray(callback)
		savings: (callback) ->
			pipeline = [
				{
					$group:
						_id: ''
						total: $sum: '$value'
				}
			]
			db.savings.aggregate pipeline, callback
	}, (err, result) ->
		if err then return res.json err

		preferences = result.preferences

		data = {}
		result.transactions.reverse()
		data.balance = result.balance
		data.savings = result.savings?[0]?.total

		poolAccounts = _.reduce result.pools, (dict, pool) ->
			dict[pool.name] = true
			dict[alias] = true for alias in pool.payoutAliases.split(',') if pool.payoutAliases?
			dict
		, {}

		poolEarnings = 0
		oldest = moment().unix()
		cutoff = moment().subtract('days', 7).unix()
		for tx in result.transactions
			if tx.category in ['receive','generate','immature'] and preferences[tx.address]?.label
				tx.account = preferences[tx.address].label
			if tx.time >= cutoff
				oldest = tx.time if tx.time < oldest
				poolEarnings += tx.amount if tx.amount > 0 and poolAccounts[tx.account]
		data.earnRate = Number((poolEarnings / 7).toFixed(4))

		data.more = if result.transactions.length > show then true else false
		data.transactions = _.chain(result.transactions).first(show).map((tx) ->
			if tx.category is 'generate' or tx.category is 'immature'
				confirmCount = 120
			else
				confirmCount = 6
			tx.confirmed = if tx.confirmations >= confirmCount then true else false
			tx
		).value()

		res.json data
	)

lastPrice = '-'
lastPriceExpiration = 0
exports.price = (req, res) ->
	return res.json usd: lastPrice if moment().unix() < lastPriceExpiration

	client = request.newClient 'https://coinbase.com/'
	client.get '/api/v1/prices/sell', (err, r, body) ->
		unless err
			lastPrice = Number(body.subtotal.amount)
			lastPriceExpiration = moment().add('seconds', 60).unix()
		res.json usd: lastPrice


exports.recentRecipients = (req, res) ->
	client = new BitcoinClient config.bitcoin

	client.listTransactions '*', 500, (err, transactions) ->
		if err then return res.json err

		transactions.reverse()
		addresses = _.chain(transactions)
		.filter((tx) -> tx.category == 'send' and tx.to?)
		.uniq(false, (tx) -> tx.address)
		.sortBy((tx) -> tx.to.toLowerCase())
		.map((tx) -> name: tx.to, address: tx.address)
		.value()
		res.json addresses

exports.sendTx = (req, res) ->
	client = new BitcoinClient config.bitcoin

	tx = req.body
	unless tx.passphrase?.length > 0 and tx.amount > 0 and tx.address?.length > 0 and isFinite(tx.amount)
		res.statusCode = 400
		res.json error: 'Error: Invalid parameters'

	async.parallel({
		validAddress: (callback) ->
			client.validateAddress tx.address, callback
		balance: (callback) ->
			client.getBalance callback
		unlock: (callback) ->
			client.walletPassphrase tx.passphrase, 30, callback
	}, (err, result) ->
		if err
			error = err.message

		unless result.validAddress?.isvalid
			error = "Error: Invalid Bitcoin Address"

		if tx.amount > result.balance
			error = 'Error: Insufficient Funds'

		if error?
			res.statusCode = 400
			res.json error: error
			return

		client.sendToAddress tx.address, Number(tx.amount), tx.comment ? '', tx.name ? '', (err, result) ->
			client.walletLock()
			if err
				res.statusCode = 500
				res.json error: err.message
				return

			res.statusCode = 200
			res.json success: true

		return

	)

exports.signMsg = (req, res) ->
	client = new BitcoinClient config.bitcoin

	msg = req.body
	unless msg.passphrase?.length > 0 and msg.address?.length > 0
		res.statusCode = 400
		res.json error: 'Error: Invalid parameters'

	async.parallel({
		validAddress: (callback) ->
			client.validateAddress msg.address, callback
		unlock: (callback) ->
			client.walletPassphrase msg.passphrase, 30, callback
	}, (err, result) ->
		if err
			error = err.message

		unless result.validAddress?.isvalid
			error = "Error: Invalid Bitcoin Address"

		if error?
			res.statusCode = 400
			res.json error: error
			return

		client.signMessage msg.address, msg.message, (err, result) ->
			client.walletLock()
			if err
				res.statusCode = 500
				res.json error: err.message
				return

			res.statusCode = 200
			res.json success: true, signature: result

		return

	)

exports.listAddresses = (req, res) ->
	client = new BitcoinClient config.bitcoin

	async.parallel({
		addresses: (callback) ->
			async.waterfall([
				(callback) ->
					client.listAccounts 0, callback
				(accountList, callback) ->
					addresses = []
					async.eachLimit(_.keys(accountList), 6, (account, callback) ->
						if account.length > 0
							client.getAddressesByAccount account, (err, result) ->
								addresses.push { label: account, address: address } for address in result unless err
								callback(err)
						else
							callback()
					, (err) ->
						callback(err, addresses)
					)
			], callback)
		preferences: (callback) ->
			getAddressPreferences(callback)
	}, (err, data) ->
		if err
			res.statusCode = 500
			res.json err

		preferences = data.preferences

		for entry in data.addresses
			entry.archived = if preferences[entry.address]?.archived then true else false
			entry.label = preferences[entry.address]?.label ? entry.label

		addresses = _.sortBy data.addresses, (a) -> a.label.toLocaleLowerCase()
		res.json addresses

	)

exports.updateAddress = (req, res) ->
	body = req.body

	unless body.address?
		res.statusCode = 400
		res.json error: 'Invalid request'
		return

	entry = {
		address: body.address
		label: body.label
		archived: if body.archived then true else false
	}

	db.addresses.update { address: entry.address }, entry, { upsert: true }
	res.json entry

exports.newAddress = (req, res) ->
	body = req.body

	unless body.label?
		res.statusCode = 400
		res.json error: 'Invalid request'
		return

	client = new BitcoinClient config.bitcoin
	client.getNewAddress body.label, (err, address) ->
		if err
			res.statusCode = 500
			res.json error: err

		res.json address: address
		return

	return


exports.bitcoinLink = (req, res) ->
	bitcoinUri = req.query.uri
	console.log bitcoinUri
	bitcoinUriPieces = url.parse(bitcoinUri)
	res.redirect "/#/wallet/send?to=#{encodeURIComponent(bitcoinUriPieces.host)}&#{bitcoinUriPieces.query}"
	return