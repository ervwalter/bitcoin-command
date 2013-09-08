request = require('request-json')

run = (pool, callback) ->
    client = request.newClient 'https://www.btcguild.com/'
    client.get "/api.php?api_key=#{pool.apiKey}", (err, r, body) ->
        return if err
        try
            pending = body.user.unpaid_rewards
            payouts = body.user.paid_rewards
            poolSize = body.pool.pool_speed * 1000
            callback { pending: pending, payouts: payouts, poolSize: poolSize }
        catch e

exports.initialize = (clients) ->
    clients.btcguild = run

