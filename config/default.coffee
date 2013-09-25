module.exports =
    port: 3000
    debug: false
    mongoDbConnectionString: 'mongodb://localhost/bitcoin'
    submitShareKey: 'secret'
    cookieSecretKey: 'password'
    authentication:
        username: 'admin'
        password: 'admin'
    bitcoin:
        host: 'hostname'
        port: 8332
        user: 'username'
        pass: 'password'
        ssl: true
        sslStrict: true
