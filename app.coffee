express = require('express')
http = require('http')
https = require('https')
fs = require('fs')
path = require('path')
step = require('step')
async = require('async')

db = require('./server/db')
security = require('./server/security')
mining = require('./server/mining')
wallet = require('./server/wallet')
pools = require('./server/poolsApi')
poolStats = require('./server/poolStats')
deviceStats = require('./server/deviceStats')
dbCleanup = require('./server/dbCleanup')
io = require('./server/io')

noCache = (req, res, next) ->
    res.header('Cache-Control', 'no-cache, private, no-store, must-revalidate');
    next()

app = express()

# all environments
app.set "port", Number(process.env.PORT or 3000)
app.set('views', __dirname + '/public');
app.set('view engine', 'ejs');
app.use express.favicon('public/favicon.ico')
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser()
app.use express.query()
app.use security.authParser()
app.use express.compress()
app.use express['static'](path.join(__dirname, "public"))
app.use app.router

# development only
app.use express.errorHandler()  #if "development" is app.get("env")

app.post '/submitshare', noCache, mining.submitshare
app.get '/mining/summary', noCache, security.requireAuthentication, mining.summarydata
app.get '/mining/chart', noCache, security.requireAuthentication, mining.chartdata

app.get '/wallet/summary', noCache, security.requireAuthentication, wallet.summary
app.get '/wallet/price', noCache, security.requireAuthentication, wallet.price
app.get '/wallet/recentRecipients', noCache, security.requireAuthentication, wallet.recentRecipients
app.post '/wallet/send', noCache, security.requireAuthentication, wallet.sendTx
app.get '/wallet/addresses', noCache, security.requireAuthentication, wallet.listAddresses
app.post '/wallet/addresses', noCache, security.requireAuthentication, wallet.updateAddress
app.post '/wallet/newaddress', noCache, security.requireAuthentication, wallet.newAddress

app.get '/pools', noCache, security.requireAuthentication, pools.getAllPools
app.post '/pools/:poolId', noCache, security.requireAuthentication, pools.savePool
app.delete '/pools/:poolId', noCache, security.requireAuthentication, pools.deletePool
app.get '/pools/:poolId', noCache, security.requireAuthentication, pools.getPool

app.post '/login', noCache, security.login
app.post '/logout', noCache, security.logout

app.get '/', (req, res) ->
    res.render "index"

db.initialize ->
    # initialize background tasks
    poolStats.initialize()
    deviceStats.initialize()
    dbCleanup.initialize()

    # setup web servers
    port = app.get("port")

    server = http.createServer(app)
    io.http = require('socket.io').listen(server)
    io.http.set('log level', 1)
    io.http.set('authorization', security.socketAuthentication)
    server.listen port, (err) ->
        throw err if err
        console.log "Express server listening on port #{port}"

    try
        options = {
            ca: fs.readFileSync('./ssl-ca.crt')
            cert: fs.readFileSync('./ssl-cert.crt')
            key: fs.readFileSync('./ssl-key.pem')
        }
        sslServer = https.createServer(options, app)
        io.https = require('socket.io').listen(sslServer)
        io.https.set('log level', 1)
        io.https.set('authorization', security.socketAuthentication)
        sslServer.listen port + 1, (err) ->
            throw err if err
            console.log "Express server listening with SSL on port #{port+1}"
    catch e



