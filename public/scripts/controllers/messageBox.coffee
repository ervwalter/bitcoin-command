###
  MessageBox Controller
###
bitcoinApp.controller 'MessageBoxCtrl', ($scope, dialog, model) ->
    $scope.title = model.title
    $scope.message = model.message
    $scope.buttons = model.buttons;
    $scope.close = (result) ->
        dialog.close(result)