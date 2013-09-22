###
  Prompt Controller
###
bitcoinApp.controller 'NewAddressCtrl', ($scope, $timeout, dialog, walletInfo) ->

    $scope.title = "New Address"
    $scope.state = 'prompt'

    $scope.create = ->
        $scope.state = 'creating'
        walletInfo.newAddress($scope.label).then((address) ->
            $scope.address = address.address
            $scope.state = 'created'
        , ->
            $scope.state = 'error'
        )

    $scope.close = ->
        dialog.close()