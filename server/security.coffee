config = require('config')
cookie = require('cookie')
utils = require('client-sessions').util

secureCookieName = 'authtoken'
statusCookieName = 'authenticated'
maxAge = 365 * 24 * 3600 * 1000

opts = {
    cookieName: secureCookieName
    secret: config.cookieSecretKey
    duration: maxAge
}

checkCookie = (cookies) ->
    authenticated = false
    authCookie = cookies[secureCookieName];
    if authCookie?
        data = utils.decode(opts, authCookie)
        if data?.content?.authenticated
            authenticated = true
    return authenticated

exports.socketAuthentication = (handshakeData, accept) ->
    cookies = cookie.parse(handshakeData.headers.cookie)
    if checkCookie(cookies)
        return accept(null, true)
    else
        return accept('Unauthorized request. Please log in first.', false)

exports.authParser = ->
    return (req, res, next) ->
        req.authenticated = checkCookie(req.cookies)
        res.cookie statusCookieName, JSON.stringify(req.authenticated), { path: '/' }
        next()
        return

exports.requireAuthentication = (req, res, next) ->
    if req.authenticated
        next()
        return
    res.statusCode = 401
    res.json error: 'Unauthorized request. Please log in first.'
    res.end()
    return

exports.login = (req, res) ->
    if req.body.username is config.authentication.username and req.body.password is config.authentication.password
        req.authenticated = true
        res.cookie statusCookieName, JSON.stringify(req.authenticated), { path: '/' }
        if req.body.rememberMe
            res.cookie secureCookieName, utils.encode(opts, { authenticated: true }), { path: '/', httpOnly: true, maxAge: maxAge }
        else
            res.cookie secureCookieName, utils.encode(opts, { authenticated: true }), { path: '/', httpOnly: true }
        res.json {success: true}
    else
        res.json {error: 'Invalid username/password'}

exports.logout = (req, res) ->
    req.authenticated = false
    res.cookie statusCookieName, JSON.stringify(req.authenticated), { path: '/' }
    res.clearCookie secureCookieName, { path: '/' }
    res.send()
