###
  Prompt Controller
###
bitcoinApp.controller 'ChangeLabelCtrl', ($scope, dialog, model) ->
    $scope.title = model.title
    $scope.address = model.address
    $scope.initial = model.label
    $scope.buttons = model.buttons;

    $scope.cancel = ->
        dialog.close({result: false})
    $scope.save = ->
        dialog.close({result: true, label: $scope.label})