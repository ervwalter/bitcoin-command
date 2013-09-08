###
    Reload Link Directive
###

bitcoinApp.directive 'reload', ($route, $location, $rootScope) ->
    return {
        restrict: 'A'
        link: (scope, element, attrs, controller) ->
            element.on 'click', ->
                if '#' + $location.path() is attrs.href
                    $route.reload()
                    $rootScope.$apply() unless $rootScope.$$phase
                return
            return
    }

