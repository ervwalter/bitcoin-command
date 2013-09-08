###
    Popups Service
###

bitcoinApp.factory 'popups', ($dialog) ->
    {
        messageBox: (title, message, buttons) ->
            $dialog.dialog {
                templateUrl: '/templates/messageBox.html'
                controller: 'MessageBoxCtrl'
                resolve: {
                    model: ->
                        {
                            title: title
                            message: message
                            buttons: buttons
                        }
                }
            }

        changeLabel: (address, label) ->
            $dialog.dialog {
                templateUrl: '/templates/changeLabel.html'
                controller: 'ChangeLabelCtrl'
                resolve: {
                    model: ->
                        {
                            address: address
                            label: label
                        }
                }
            }

        newAddress: ->
            $dialog.dialog {
                templateUrl: '/templates/newAddress.html'
                controller: 'NewAddressCtrl'
            }
    }

