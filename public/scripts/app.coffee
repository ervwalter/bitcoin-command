###
	Main Module
###

bitcoinApp = angular.module('bitcoinApp', ['ngRoute', 'ngCookies', 'ngResource', 'ngSanitize', 'ui.validate','ui.bootstrap', 'interval'])
.config ($routeProvider, $httpProvider) ->
		requireAuthentication = (original = {}) ->
			resolver = {}
			_.extend(resolver, original, {
				__authentication: ($q, authentication) ->
					if authentication.isAuthenticated()
						deferred = $q.defer()
						deferred.resolve()
						return deferred.promise
					else
						return $q.reject('/login')
			})
			return resolver

		anonymous = (original = {}) ->
			return original

		interceptor = ($location, $q) ->
			success = (response) ->
				return response

			error = (response) ->
				if response.status is 401
					console.log 'oops, session appears to be expired'
					$location.path '/login'
					return $q.reject(response)
				else
					return $q.reject(response)

			return (promise) ->
				promise.then(success, error)
		$httpProvider.responseInterceptors.push(interceptor)

		$routeProvider.when '/dashboard', {
			templateUrl: '/templates/dashboard.html'
			controller: 'DashboardCtrl'
			title: 'Dashboard'
			resolve: requireAuthentication()
		}

		$routeProvider.when '/pools', {
			templateUrl: '/templates/pools.html'
			controller: 'PoolsCtrl'
			title: 'Pools'
			resolve: requireAuthentication()
		}

		$routeProvider.when '/pools/:poolId', {
			templateUrl: '/templates/poolEdit.html'
			controller: 'PoolEditCtrl'
			title: 'Edit Pool'
			resolve: requireAuthentication()
		}

		$routeProvider.when '/wallet', {
			templateUrl: '/templates/wallet.html'
			controller: 'WalletCtrl'
			title: 'Wallet'
			resolve: requireAuthentication()
		}

		$routeProvider.when '/wallet/send', {
			templateUrl: '/templates/send.html'
			controller: 'SendCtrl'
			title: 'Send Bitcoins'
			resolve: requireAuthentication()
		}

		$routeProvider.when '/wallet/sign', {
			templateUrl: '/templates/sign.html'
			controller: 'SignCtrl'
			title: 'Sign Message'
			resolve: requireAuthentication()
		}

		$routeProvider.when '/wallet/addresses', {
			templateUrl: '/templates/addressList.html'
			controller: 'AddressListCtrl'
			title: 'Addresses'
			resolve: requireAuthentication()
		}

		$routeProvider.when '/login', {
			templateUrl: '/templates/login.html'
			controller: 'LoginCtrl'
			title: 'Login'
			resolve: anonymous()
		}

		$routeProvider.otherwise {
			redirectTo: '/dashboard'
		}

.run ($rootScope, $location) ->
		$rootScope.$on '$routeChangeError', (event, current, previous, rejection) ->
			if rejection is '/login'
				$location.path '/login'
			return

		$rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
			$rootScope.pageTitle = current?.$$route?.title
			return

		return
