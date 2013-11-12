###
  Wallet Controller
###
bitcoinApp.controller 'WalletCtrl', ($scope, walletInfo, popups) ->

    $scope.count = 50
    $scope.wallet = walletInfo.getSummary($scope.count)
    $scope.filterTerm = ''

    $scope.newAddress = ->
        popups.newAddress().open()

    $scope.show = (count) ->
        $(document.body).addClass('wait')
        $scope.wallet.$get({show: count}).then ->
            $scope.count = count
            $(document.body).removeClass('wait')

    $scope.clearFilterTerm = ->
        $scope.filterTerm = ''

    $scope.filterTermKeyDown = (event) ->
        $scope.clearFilterTerm() if event.keyCode is 27
