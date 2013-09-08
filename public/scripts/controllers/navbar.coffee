###
    NavBar Controller
###

bitcoinApp.controller 'NavbarCtrl', ($scope, $route, $location, $rootScope, authentication) ->
    $scope.navCollapsed = true
    $scope.authenticated = authentication.isAuthenticated()
    $scope.$on 'authenticationChanged', ->
        $scope.authenticated = authentication.isAuthenticated()

    $scope.logout = ->
        authentication.logout ->
            $location.path '/'
        return

    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        $scope.navCollapsed = true
        return
