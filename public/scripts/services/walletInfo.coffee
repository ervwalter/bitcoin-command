###
    Wallet Service
###

bitcoinApp.factory 'walletInfo', ($resource, $http, $q) ->
    summary = $resource '/wallet/summary'
    price = $resource '/wallet/price'
    recipients = $resource '/wallet/recentRecipients', {}, { 'get': {method: 'GET', isArray: true} }
    addresses = $resource '/wallet/addresses'

    return {
        getSummary: (num) ->
            summary.get({show: num})
        getPrice: ->
            price.get()
        getRecentRecipients: ->
            recipients.get()
        getAddresses: ->
            addresses.query()
        newAddress: (label) ->
            deferred = $q.defer()
            $http.post('/wallet/newaddress', label: label).success((address) -> deferred.resolve(address)).error(-> deferred.reject())
            return deferred.promise
        sendTx: (tx) ->
            deferred = $q.defer()
            $http({
                method: 'POST'
                url: '/wallet/send'
                data: tx
            }).success(->
                deferred.resolve()
            ).error((data, status) ->
                deferred.reject(data.error)
            )
            return deferred.promise
    }


