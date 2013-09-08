###
    Authentication Service
###

bitcoinApp.factory 'authentication', ($http, $rootScope, $cookieStore) ->

    #read from the cookie at first load
    authenticated = $cookieStore.get('authenticated') || false

    changeAuthenticated = (newValue) ->
        if authenticated is not newValue
            authenticated = newValue
            $rootScope.$broadcast('authenticationChanged')

    return {
        isAuthenticated: ->
            authenticated


        login: (username, password, rememberMe, success, error) ->
            $http.post('/login', {username: username, password: password, rememberMe: rememberMe}).success( (response) ->
                if response.success
                    changeAuthenticated(true)
                    success?()
                else
                    error(response.error)
                return
            ).error(->
                error?()
                return
            )

        logout: (success, error) ->
            $http.post('/logout').success(->
                changeAuthenticated(false)
                success?()
            ).error(error)
    }