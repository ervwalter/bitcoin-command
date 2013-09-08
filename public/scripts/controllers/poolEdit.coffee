###
  Pool Edit Controller
###
bitcoinApp.controller 'PoolEditCtrl', ($scope, $location, $routeParams, pools) ->
    $scope.pool = pools.get($routeParams.poolId)
    $scope.save = (pool) ->
        pool.$save().then -> $location.path '/pools'

    return