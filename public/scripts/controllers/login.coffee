###
  Login Controller
###
bitcoinApp.controller 'LoginCtrl', ($scope, $location, authentication) ->
    $scope.login = ->
        authentication.login($scope.username, $scope.password, $scope.rememberMe, ->
            $location.path('/')
        , (error) ->
            console.log error
            $scope.error = error or 'Unknown error.  Try again later.'
        )
