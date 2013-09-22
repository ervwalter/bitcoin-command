###
  QR Code Controller
###
bitcoinApp.controller 'ShowAddressCtrl', ($scope, dialog, model) ->

    $scope.title = "Bitcoin Address"
    $scope.state = 'created'
    $scope.address = model.address
    $scope.label = model.label

    $scope.close = ->
        dialog.close()