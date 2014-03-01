###
  Send / Sell Controller
###
bitcoinApp.controller 'SendCtrl', ($scope, popups, $location, $timeout, walletInfo) ->

	query = $location.search()
	$scope.tx = {
		address: query.to
		name: query.label
		amount: query.amount
		comment: query.message
	}
	$scope.status = {}
	$scope.wallet = walletInfo.getSummary(1)
	$scope.recentRecipients = walletInfo.getRecentRecipients()
	$scope.sending = false

	$scope.formatAddress = (item) ->
		item?.address

	$scope.selectedAddress = (item) ->
		$scope.tx.name = item.name
		# This is kind of a violation of AngularJS "rules" because a controller is touching the DOM
		# but the alternative solution of creating a directive to do this one line of code indirectly
		# is too messy, IMHO.  So I'm going to break the rule...
		$timeout -> $('input[name=amount]').focus()

	$scope.positive = (amount) ->
		$.trim(amount) is '' or amount >= 0.00000001

	$scope.underBalance = (amount) ->
		if $scope.wallet.balance? and amount >= 0.00000001
			amount <= $scope.wallet.balance
		else
			true

	$scope.send = (tx) ->
		recipient = if tx.name? then "<b>#{tx.name}</b> (#{tx.address})" else "<b>#{tx.address}</b>"
		message = "Send <b>#{tx.amount}</b> BTC to #{recipient}?"
		popups.messageBox("Please confirm", message, [
			{result: true, label: 'Yes, Send It', cssClass: 'btn-success btn-small'}
			{result: false, label: 'No, I Changed My Mind', cssClass: 'btn-danger btn-small'}
		]).open().then((result) ->
			if result
				$scope.sending = true
				$scope.error = ''
				walletInfo.sendTx(tx).then(->
					$location.path '/wallet'
				, (error) ->
					$scope.sending = false
					$scope.error = error
				)
		)

###
	$scope.recentRecipients = {
		name: 'recentRecipients'
		prefetch: {
			url: '/wallet/recentRecipients'
			filter: (response) ->
				_.map response, (item) ->
					{
						value: item.address
						name: item.name
						address: item.address
						shortAddress: item.address.substr(0, 10) + '...'
						tokens: _.union(item.name.split(' '))
					}
			ttl: 0
		}
		header: '<h3>Recent Recipients</h3>'
		template: [
			'<span>'
			'<span class="address-name">[[name]]</span>'
			' - '
			'<span class="address-value visible-desktop">[[address]]</span>'
			'<span class="address-value hidden-desktop">[[shortAddress]]</span>'
			'</span>'
		].join('')
		engine: HoganWrapper
	}
###
