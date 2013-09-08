###
  Pools Controller
###
bitcoinApp.controller 'PoolsCtrl', ($scope, $location, pools) ->

    $scope.pools = pools.getAll()

    $scope.toggleEnabled = (pool) ->
        pool.enabled = !pool.enabled
        pools.save(pool)

    $scope.deletePool = (pool) ->
        pools.delete(pool._id)
        index = _.indexOf($scope.pools, pool)
        $scope.pools.splice(index, 1) if index >= 0

    $scope.editPool = (pool) ->
        $location.path '/pools/' + pool._id

    return