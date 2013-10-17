###
  Sign Controller
###
bitcoinApp.controller 'SignCtrl', ($scope, popups, $location, $timeout, walletInfo) ->
	$scope.msg = {}
	$scope.status = {}
	$scope.addresses = walletInfo.getAddresses()
	$scope.signing = false
	$scope.signed = false

	$scope.selectedAddress = (item) ->
		# This is kind of a violation of AngularJS "rules" because a controller is touching the DOM
		# but the alternative solution of creating a directive to do this one line of code indirectly
		# is too messy, IMHO.  So I'm going to break the rule...
		$timeout -> $('textarea[name=message]').focus()

	$scope.$watchCollection '[msg.address, msg.message, msg.passphrase]', ->
		$scope.signed = false

	$scope.sign = (msg) ->
		$scope.signed = false
		$scope.signing = true
		$scope.error = ''
		walletInfo.signMsg(msg).then((signature) ->
			$scope.signature = signature
			$scope.signed = true
			$scope.signing = false
		, (error) ->
			$scope.signing = false
			$scope.error = error
		)

