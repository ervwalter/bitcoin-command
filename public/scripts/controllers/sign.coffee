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

	$scope.sign = (msg) ->
		$scope.signed = false
		$scope.sending = true
		$scope.error = ''
		console.log msg
		walletInfo.signMsg(msg).then((signature) ->
			$scope.signature = signature
			$scope.signed = true
			$scope.sending = false
		, (error) ->
			$scope.sending = false
			$scope.error = error
		)

