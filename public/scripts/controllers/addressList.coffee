###
  Address List Controller
###
bitcoinApp.controller 'AddressListCtrl', ($scope, walletInfo, popups) ->
    $scope.loading = true
    $scope.addresses = walletInfo.getAddresses()
    $scope.addresses.$promise.then -> $scope.loading = false
    $scope.showArchived = false

    $scope.toggleArchived = (item) ->
        item.archived = !item.archived
        item.$save()
        return

    $scope.rename = (item) ->
        popups.changeLabel(item.address, item.label).open().then((result) ->
            if result?.result
                item.label = result.label
                item.$save()
            return
        )
        return

    return