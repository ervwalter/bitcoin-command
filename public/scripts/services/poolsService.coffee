###
    Pools Service
###

bitcoinApp.factory 'pools', ($resource) ->
    resource = $resource('/pools/:id', {id:'@_id'}, {
        delete: {
            method: 'DELETE'
            params: {id: '@_id'}
        }
    })

    {
        getAll: ->
            resource.query()
        get: (id) ->
            resource.get({id: id})
        save: (pool) ->
            pool.$save()
        delete: (id) ->
            resource.delete({id: id})
    }


