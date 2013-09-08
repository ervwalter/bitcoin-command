###
    Transaction List Directive
###

bitcoinApp.directive 'transactionList', ->
    return {
        restrict: 'E'
        replace: true
        templateUrl: '/templates/directives/transactionList.html'
        scope: {
            transactions: '='
        }
    }

