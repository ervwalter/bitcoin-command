(function () {
  var bitcoinApp, getFieldValidationExpression, hashrateFilter;
  bitcoinApp = angular.module('bitcoinApp', [
    'ngRoute',
    'ngCookies',
    'ngResource',
    'ngSanitize',
    'ui.validate',
    'ui.bootstrap',
    'interval'
  ]).config([
    '$routeProvider',
    '$httpProvider',
    function ($routeProvider, $httpProvider) {
      var anonymous, interceptor, requireAuthentication;
      requireAuthentication = function (original) {
        var resolver;
        if (original == null) {
          original = {};
        }
        resolver = {};
        _.extend(resolver, original, {
          __authentication: function ($q, authentication) {
            var deferred;
            if (authentication.isAuthenticated()) {
              deferred = $q.defer();
              deferred.resolve();
              return deferred.promise;
            } else {
              return $q.reject('/login');
            }
          }
        });
        return resolver;
      };
      anonymous = function (original) {
        if (original == null) {
          original = {};
        }
        return original;
      };
      interceptor = function ($location, $q) {
        var error, success;
        success = function (response) {
          return response;
        };
        error = function (response) {
          if (response.status === 401) {
            console.log('oops, session appears to be expired');
            $location.path('/login');
            return $q.reject(response);
          } else {
            return $q.reject(response);
          }
        };
        return function (promise) {
          return promise.then(success, error);
        };
      };
      $httpProvider.responseInterceptors.push(interceptor);
      $routeProvider.when('/dashboard', {
        templateUrl: '/templates/dashboard.html',
        controller: 'DashboardCtrl',
        title: 'Dashboard',
        resolve: requireAuthentication()
      });
      $routeProvider.when('/pools', {
        templateUrl: '/templates/pools.html',
        controller: 'PoolsCtrl',
        title: 'Pools',
        resolve: requireAuthentication()
      });
      $routeProvider.when('/pools/:poolId', {
        templateUrl: '/templates/poolEdit.html',
        controller: 'PoolEditCtrl',
        title: 'Edit Pool',
        resolve: requireAuthentication()
      });
      $routeProvider.when('/wallet', {
        templateUrl: '/templates/wallet.html',
        controller: 'WalletCtrl',
        title: 'Wallet',
        resolve: requireAuthentication()
      });
      $routeProvider.when('/wallet/send', {
        templateUrl: '/templates/send.html',
        controller: 'SendCtrl',
        title: 'Send Bitcoins',
        resolve: requireAuthentication()
      });
      $routeProvider.when('/wallet/sign', {
        templateUrl: '/templates/sign.html',
        controller: 'SignCtrl',
        title: 'Sign Message',
        resolve: requireAuthentication()
      });
      $routeProvider.when('/wallet/addresses', {
        templateUrl: '/templates/addressList.html',
        controller: 'AddressListCtrl',
        title: 'Addresses',
        resolve: requireAuthentication()
      });
      $routeProvider.when('/login', {
        templateUrl: '/templates/login.html',
        controller: 'LoginCtrl',
        title: 'Login',
        resolve: anonymous()
      });
      return $routeProvider.otherwise({ redirectTo: '/dashboard' });
    }
  ]).run([
    '$rootScope',
    '$location',
    function ($rootScope, $location) {
      $rootScope.$on('$routeChangeError', function (event, current, previous, rejection) {
        if (rejection === '/login') {
          $location.path('/login');
        }
      });
      $rootScope.$on('$routeChangeSuccess', function (event, current, previous) {
        var _ref;
        $rootScope.pageTitle = current != null ? (_ref = current.$$route) != null ? _ref.title : void 0 : void 0;
      });
    }
  ]);
  bitcoinApp.controller('AddressListCtrl', [
    '$scope',
    'walletInfo',
    'popups',
    function ($scope, walletInfo, popups) {
      $scope.loading = true;
      $scope.addresses = walletInfo.getAddresses();
      $scope.addresses.$promise.then(function () {
        return $scope.loading = false;
      });
      $scope.showArchived = false;
      $scope.toggleArchived = function (item) {
        item.archived = !item.archived;
        item.$save();
      };
      $scope.rename = function (item) {
        popups.changeLabel(item.address, item.label).open().then(function (result) {
          if (result != null ? result.result : void 0) {
            item.label = result.label;
            item.$save();
          }
        });
      };
      $scope.qr = function (item) {
        popups.showAddress(item.address, item.label).open();
      };
    }
  ]);
  bitcoinApp.controller('ChangeLabelCtrl', [
    '$scope',
    'dialog',
    'model',
    function ($scope, dialog, model) {
      $scope.title = model.title;
      $scope.address = model.address;
      $scope.initial = model.label;
      $scope.buttons = model.buttons;
      $scope.cancel = function () {
        return dialog.close({ result: false });
      };
      return $scope.save = function () {
        return dialog.close({
          result: true,
          label: $scope.label
        });
      };
    }
  ]);
  bitcoinApp.controller('DashboardCtrl', [
    '$scope',
    '$timeout',
    'miningStats',
    'walletInfo',
    'authentication',
    'socket',
    'safeIdFilter',
    function ($scope, $timeout, miningStats, walletInfo, authentication, socket, safeIdFilter) {
      var chartConfig, miningTimeout, oncePerMinute, oncePerTenSeconds, sixtySeconds, tenSeconds, updateChart, updateMiningSummary, updatePrice, updateWallet, walletTimeout;
      $scope.authenticated = authentication.isAuthenticated();
      $scope.mining = miningStats.getSummary();
      $scope.wallet = walletInfo.getSummary(5);
      $scope.price = walletInfo.getPrice();
      updateMiningSummary = function () {
        return $scope.mining.$get();
      };
      updatePrice = function () {
        return $scope.price.$get();
      };
      updateWallet = function () {
        return $scope.wallet.$get({ show: 5 });
      };
      Highcharts.setOptions({ global: { useUTC: false } });
      chartConfig = {
        chart: {
          backgroundColor: '#f6f6f6',
          type: 'area',
          animation: true
        },
        credits: { enabled: false },
        colors: [
          '#4572a7',
          '#aa4643',
          '#80699b',
          '#3d96ae',
          '#db843d'
        ],
        plotOptions: {
          area: {
            fillOpacity: 0.5,
            lineWidth: 1
          },
          series: {
            animation: false,
            marker: { enabled: false },
            stacking: 'normal'
          }
        },
        xAxis: {
          type: 'datetime',
          tickInterval: 24 * 3600 * 1000,
          gridLineWidth: 1,
          endOnTick: false
        },
        yAxis: {
          min: 0,
          showFirstLabel: false,
          endOnTick: false,
          title: { text: null },
          labels: {
            formatter: function () {
              return hashrateFilter(this.value);
            }
          }
        },
        loading: true,
        title: { text: 'Hash Rate, Past 3 Days' }
      };
      updateChart = function () {
        return miningStats.getChart().$promise.then(function (chartData) {
          var _ref;
          chartConfig.plotOptions.series.pointInterval = chartData.pointInterval;
          chartConfig.plotOptions.series.pointStart = chartData.pointStart;
          chartConfig.series = chartData.series;
          chartConfig.loading = false;
          if ((_ref = $('#chart').highcharts()) != null) {
            _ref.destroy();
          }
          $('#chart').highcharts(chartConfig);
        });
      };
      updateChart();
      socket.on('share', function (data) {
        var device, deviceId, id, pool, poolId, _i, _len, _ref;
        if ($scope.mining.devices != null) {
          poolId = '#pool-' + safeIdFilter(data.pool);
          deviceId = '#device-' + safeIdFilter(data.hostname + ':' + data.device);
          _ref = [
            poolId,
            deviceId
          ];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            id = _ref[_i];
            $(id).stop().clearQueue().fadeTo(0, 1).fadeTo(700, 0);
          }
          device = _.find($scope.mining.devices[data.hostname], function (d) {
            return d.device === data.device;
          });
          pool = _.find($scope.mining.pools, function (p) {
            return p.name === data.pool;
          });
          if (device != null && pool != null) {
            device.lastPool = data.pool;
            device.lastShare = moment().unix();
            return pool.lastShare = moment().unix();
          } else {
            console.log('Detected new device/pool');
            updateMiningSummary();
            return updateChart();
          }
        }
      });
      sixtySeconds = 60000;
      oncePerMinute = $timeout(miningTimeout = function () {
        updateMiningSummary();
        updateChart();
        updatePrice();
        oncePerMinute = $timeout(miningTimeout, sixtySeconds);
      }, sixtySeconds);
      tenSeconds = 10000;
      oncePerTenSeconds = $timeout(walletTimeout = function () {
        updateWallet();
        oncePerTenSeconds = $timeout(walletTimeout, tenSeconds);
      }, tenSeconds);
      return $scope.$on('$destroy', function () {
        socket.removeAllListeners();
        if (oncePerTenSeconds) {
          $timeout.cancel(oncePerTenSeconds);
        }
        if (oncePerMinute) {
          return $timeout.cancel(oncePerMinute);
        }
      });
    }
  ]);
  bitcoinApp.controller('LoginCtrl', [
    '$scope',
    '$location',
    'authentication',
    function ($scope, $location, authentication) {
      return $scope.login = function () {
        return authentication.login($scope.username, $scope.password, $scope.rememberMe, function () {
          return $location.path('/');
        }, function (error) {
          console.log(error);
          return $scope.error = error || 'Unknown error.  Try again later.';
        });
      };
    }
  ]);
  bitcoinApp.controller('LogoutCtrl', [
    '$location',
    function ($location) {
      return $location.path('/');
    }
  ]);
  bitcoinApp.controller('MessageBoxCtrl', [
    '$scope',
    'dialog',
    'model',
    function ($scope, dialog, model) {
      $scope.title = model.title;
      $scope.message = model.message;
      $scope.buttons = model.buttons;
      return $scope.close = function (result) {
        return dialog.close(result);
      };
    }
  ]);
  bitcoinApp.controller('NavbarCtrl', [
    '$scope',
    '$route',
    '$location',
    '$rootScope',
    'authentication',
    function ($scope, $route, $location, $rootScope, authentication) {
      $scope.navCollapsed = true;
      $scope.authenticated = authentication.isAuthenticated();
      $scope.$on('authenticationChanged', function () {
        return $scope.authenticated = authentication.isAuthenticated();
      });
      $scope.logout = function () {
        authentication.logout(function () {
          return $location.path('/');
        });
      };
      return $rootScope.$on('$routeChangeSuccess', function (event, current, previous) {
        $scope.navCollapsed = true;
      });
    }
  ]);
  bitcoinApp.controller('NewAddressCtrl', [
    '$scope',
    '$timeout',
    'dialog',
    'walletInfo',
    function ($scope, $timeout, dialog, walletInfo) {
      $scope.title = 'New Address';
      $scope.state = 'prompt';
      $scope.create = function () {
        $scope.state = 'creating';
        return walletInfo.newAddress($scope.label).then(function (address) {
          $scope.address = address.address;
          return $scope.state = 'created';
        }, function () {
          return $scope.state = 'error';
        });
      };
      return $scope.close = function () {
        return dialog.close();
      };
    }
  ]);
  bitcoinApp.controller('PoolEditCtrl', [
    '$scope',
    '$location',
    '$routeParams',
    'pools',
    function ($scope, $location, $routeParams, pools) {
      $scope.pool = pools.get($routeParams.poolId);
      $scope.save = function (pool) {
        return pool.$save().then(function () {
          return $location.path('/pools');
        });
      };
    }
  ]);
  bitcoinApp.controller('PoolsCtrl', [
    '$scope',
    '$location',
    'pools',
    function ($scope, $location, pools) {
      $scope.pools = pools.getAll();
      $scope.toggleEnabled = function (pool) {
        pool.enabled = !pool.enabled;
        return pools.save(pool);
      };
      $scope.deletePool = function (pool) {
        var index;
        pools['delete'](pool.id);
        index = _.indexOf($scope.pools, pool);
        if (index >= 0) {
          return $scope.pools.splice(index, 1);
        }
      };
      $scope.editPool = function (pool) {
        return $location.path('/pools/' + pool.id);
      };
    }
  ]);
  bitcoinApp.controller('SendCtrl', [
    '$scope',
    'popups',
    '$location',
    '$timeout',
    'walletInfo',
    function ($scope, popups, $location, $timeout, walletInfo) {
      var query;
      query = $location.search();
      $scope.tx = {
        address: query.to,
        name: query.label,
        amount: query.amount,
        comment: query.message
      };
      $scope.status = {};
      $scope.wallet = walletInfo.getSummary(1);
      $scope.recentRecipients = walletInfo.getRecentRecipients();
      $scope.sending = false;
      $scope.formatAddress = function (item) {
        return item != null ? item.address : void 0;
      };
      $scope.selectedAddress = function (item) {
        $scope.tx.name = item.name;
        return $timeout(function () {
          return $('input[name=amount]').focus();
        });
      };
      $scope.positive = function (amount) {
        return $.trim(amount) === '' || amount >= 1e-8;
      };
      $scope.underBalance = function (amount) {
        if ($scope.wallet.balance != null && amount >= 1e-8) {
          return amount <= $scope.wallet.balance;
        } else {
          return true;
        }
      };
      return $scope.send = function (tx) {
        var message, recipient;
        recipient = tx.name != null ? '<b>' + tx.name + '</b> (' + tx.address + ')' : '<b>' + tx.address + '</b>';
        message = 'Send <b>' + tx.amount + '</b> BTC to ' + recipient + '?';
        return popups.messageBox('Please confirm', message, [
          {
            result: true,
            label: 'Yes, Send It',
            cssClass: 'btn-success btn-small'
          },
          {
            result: false,
            label: 'No, I Changed My Mind',
            cssClass: 'btn-danger btn-small'
          }
        ]).open().then(function (result) {
          if (result) {
            $scope.sending = true;
            $scope.error = '';
            return walletInfo.sendTx(tx).then(function () {
              return $location.path('/wallet');
            }, function (error) {
              $scope.sending = false;
              return $scope.error = error;
            });
          }
        });
      };
    }
  ]);
  bitcoinApp.controller('ShowAddressCtrl', [
    '$scope',
    'dialog',
    'model',
    function ($scope, dialog, model) {
      $scope.title = 'Bitcoin Address';
      $scope.state = 'created';
      $scope.address = model.address;
      $scope.label = model.label;
      return $scope.close = function () {
        return dialog.close();
      };
    }
  ]);
  bitcoinApp.controller('SignCtrl', [
    '$scope',
    'popups',
    '$location',
    '$timeout',
    'walletInfo',
    function ($scope, popups, $location, $timeout, walletInfo) {
      $scope.msg = {};
      $scope.status = {};
      $scope.addresses = walletInfo.getAddresses();
      $scope.signing = false;
      $scope.signed = false;
      $scope.selectedAddress = function (item) {
        return $timeout(function () {
          return $('textarea[name=message]').focus();
        });
      };
      $scope.$watchCollection('[msg.address, msg.message, msg.passphrase]', function () {
        return $scope.signed = false;
      });
      return $scope.sign = function (msg) {
        $scope.signed = false;
        $scope.signing = true;
        $scope.error = '';
        return walletInfo.signMsg(msg).then(function (signature) {
          $scope.signature = signature;
          $scope.signed = true;
          return $scope.signing = false;
        }, function (error) {
          $scope.signing = false;
          return $scope.error = error;
        });
      };
    }
  ]);
  bitcoinApp.controller('WalletCtrl', [
    '$scope',
    'walletInfo',
    'popups',
    function ($scope, walletInfo, popups) {
      $scope.count = 50;
      $scope.wallet = walletInfo.getSummary($scope.count);
      $scope.filterTerm = '';
      $scope.newAddress = function () {
        return popups.newAddress().open();
      };
      $scope.show = function (count) {
        $(document.body).addClass('wait');
        return $scope.wallet.$get({ show: count }).then(function () {
          $scope.count = count;
          return $(document.body).removeClass('wait');
        });
      };
      $scope.clearFilterTerm = function () {
        return $scope.filterTerm = '';
      };
      $scope.filterTermKeyDown = function (event) {
        if (event.keyCode === 27) {
          return $scope.clearFilterTerm();
        }
      };
      return $scope.registerProtocol = function () {
        var uri;
        uri = '' + window.location.protocol + '//' + window.location.host + '/wallet/bitcoinlink?uri=%s';
        return window.navigator.registerProtocolHandler('bitcoin', uri, 'Bitcoin Command');
      };
    }
  ]);
  bitcoinApp.directive('commitOnChange', [
    '$timeout',
    function ($timeout) {
      return {
        require: 'ngModel',
        link: function ($scope, $element, $attrs, modelCtrl) {
          var $setViewValue, bufferViewValue, bufferedValue, flushViewValue, onChange;
          bufferedValue = void 0;
          onChange = function (e) {
            return $timeout(flushViewValue);
          };
          bufferViewValue = function (value) {
            return bufferedValue = value;
          };
          flushViewValue = function () {
            return $setViewValue.call(modelCtrl, bufferedValue);
          };
          $setViewValue = modelCtrl.$setViewValue;
          modelCtrl.$setViewValue = bufferViewValue;
          return $element.bind('change', onChange);
        }
      };
    }
  ]);
  bitcoinApp.directive('reload', [
    '$route',
    '$location',
    '$rootScope',
    function ($route, $location, $rootScope) {
      return {
        restrict: 'A',
        link: function (scope, element, attrs, controller) {
          element.on('click', function () {
            if ('#' + $location.path() === attrs.href) {
              $route.reload();
              if (!$rootScope.$$phase) {
                $rootScope.$apply();
              }
            }
          });
        }
      };
    }
  ]);
  bitcoinApp.directive('transactionList', function () {
    return {
      restrict: 'E',
      replace: true,
      templateUrl: '/templates/directives/transactionList.html',
      scope: {
        transactions: '=',
        filter: '='
      }
    };
  });
  getFieldValidationExpression = function (formName, fieldName, attrs) {
    var dirtyExpression, fieldExpression, invalidExpression, key, watchExpression;
    if (attrs == null) {
      attrs = null;
    }
    fieldExpression = formName + '.' + fieldName;
    invalidExpression = '' + fieldExpression + '.$invalid';
    dirtyExpression = '' + fieldExpression + '.$dirty';
    watchExpression = '[' + invalidExpression + ',' + dirtyExpression;
    if (attrs != null) {
      for (key in attrs) {
        if (attrs.hasOwnProperty(key) && key !== 'for' && key !== 'class' && key.substr(0, 1) !== '$') {
          watchExpression += ',' + fieldExpression + '.$error.' + key;
        }
      }
    }
    watchExpression += ']';
    return watchExpression;
  };
  bitcoinApp.filter('validationFieldFlattener', function () {
    return function (field) {
      return JSON.stringify([
        field.$invalid,
        field.$dirty,
        field.$error
      ]);
    };
  });
  bitcoinApp.directive('controlGroup', function () {
    return {
      restrict: 'E',
      require: '^form',
      replace: true,
      transclude: true,
      template: '<div class="control-group" ng-transclude></div>',
      link: function ($scope, el, attrs, ctrl) {
        var fieldName, formName, watchExpression;
        formName = ctrl.$name;
        fieldName = attrs['for'];
        watchExpression = getFieldValidationExpression(formName, fieldName);
        return $scope.$watchCollection(watchExpression, function () {
          var error, errors, field, hasError;
          field = $scope[formName][fieldName];
          if (field.$pristine) {
            return;
          }
          hasError = false;
          errors = field.$error;
          for (error in errors) {
            if (errors.hasOwnProperty(error)) {
              if (errors[error]) {
                hasError = true;
                break;
              }
            }
          }
          if (hasError) {
            return el.addClass('error');
          } else {
            return el.removeClass('error');
          }
        });
      }
    };
  });
  bitcoinApp.directive('validationMessage', function () {
    return {
      restrict: 'E',
      require: '^form',
      replace: true,
      template: '<div class="help-block"></div>',
      link: function ($scope, el, attrs, ctrl) {
        var fieldName, formName, watchExpression;
        formName = ctrl.$name;
        fieldName = attrs['for'];
        watchExpression = getFieldValidationExpression(formName, fieldName, attrs);
        return $scope.$watchCollection(watchExpression, function () {
          var error, errors, field, html, show;
          field = $scope[formName][fieldName];
          show = field.$invalid && field.$dirty;
          el.css('display', show ? '' : 'none');
          html = '';
          if (show) {
            errors = field.$error;
            for (error in errors) {
              if (errors.hasOwnProperty(error)) {
                if (errors[error] && attrs[error]) {
                  html += '<span>' + attrs[error] + ' </span>';
                }
              }
            }
          }
          return el.html(html);
        });
      }
    };
  });
  bitcoinApp.directive('submitButton', function () {
    return {
      restrict: 'E',
      require: '^form',
      transclude: true,
      replace: true,
      template: '<button ' + 'type="submit" ' + 'class="btn btn-success" ' + 'ng-transclude>' + '</button>',
      link: function ($scope, el, attrs, ctrl) {
        var watchExpression;
        watchExpression = ctrl.$name + '.$invalid';
        return $scope.$watch(watchExpression, function (value) {
          return attrs.$set('disabled', !!value);
        });
      }
    };
  });
  bitcoinApp.directive('validSubmit', function () {
    return {
      restrict: 'A',
      require: 'form',
      link: function ($scope, el, attrs, ctrl) {
        var $element;
        $element = angular.element(el);
        attrs.$set('novalidate', 'novalidate');
        return $element.bind('submit', function (e) {
          var form;
          e.preventDefault();
          $element.find('.ng-pristine').removeClass('ng-pristine');
          form = $scope[ctrl.$name];
          angular.forEach(form, function (formElement, fieldName) {
            if (fieldName[0] === '$') {
              return;
            }
            formElement.$pristine = false;
            formElement.$dirty = true;
          });
          if (form.$invalid) {
            $element.find('.ng-invalid').first().focus();
            $scope.$apply();
            return false;
          }
          $scope.$eval(attrs.validSubmit);
          return $scope.$apply();
        });
      }
    };
  });
  hashrateFilter = null;
  bitcoinApp.filter('archived', function () {
    return function (array, archived) {
      if (archived == null) {
        archived = true;
      }
      return _.filter(array, function (item) {
        var _ref;
        return ((_ref = item.archived) != null ? _ref : false) === archived;
      });
    };
  });
  bitcoinApp.filter('safeId', function () {
    return function (input) {
      return CryptoJS.MD5(input).toString();
    };
  });
  bitcoinApp.filter('hashrate', function () {
    return hashrateFilter = function (input) {
      var hashrate, units;
      hashrate = Number(input);
      if (isNaN(hashrate) || hashrate <= 0) {
        return '-';
      }
      units = 'MH';
      if (hashrate >= 1000) {
        hashrate /= 1000;
        units = 'GH';
      }
      if (hashrate >= 1000) {
        hashrate /= 1000;
        units = 'TH';
      }
      if (hashrate >= 1000) {
        hashrate /= 1000;
        units = 'PH';
      }
      hashrate = hashrate.toPrecision(3);
      return '' + hashrate + ' ' + units + '/s';
    };
  });
  bitcoinApp.filter('confirmationCount', [
    'numberFilter',
    function (numberFilter) {
      return function (transaction) {
        if (transaction.confirmed) {
          return '\u2713';
        } else {
          return numberFilter(transaction.confirmations, '0');
        }
      };
    }
  ]);
  bitcoinApp.filter('transactionDescription', function () {
    return function (tx) {
      var msg;
      msg = '';
      switch (tx.category) {
      case 'receive':
        msg = tx.account != null ? tx.account : tx.address;
        break;
      case 'send':
        msg = 'to: ';
        if (tx.to != null) {
          msg += tx.to;
        } else {
          msg += tx.address;
        }
        if (tx.comment != null) {
          msg += ' (' + tx.comment + ')';
        }
        if (tx.fee < 0) {
          msg += ', fee: ' + tx.fee * -1;
        }
        break;
      case 'generate':
      case 'immature':
        if (tx.account != null) {
          msg += '' + tx.account + ', ';
        }
        msg += 'generated';
        break;
      default:
        msg = 'unknown';
      }
      return msg;
    };
  });
  bitcoinApp.filter('bitcoin', [
    'numberFilter',
    function (numberFilter) {
      return function (amount) {
        var formatted, i, length;
        formatted = numberFilter(amount, 8);
        if (formatted !== '') {
          i = 0;
          length = formatted.length;
          while (i < 6) {
            if (formatted.substr(length - i - 1, 1) !== '0') {
              break;
            }
            i++;
          }
          formatted = formatted.substr(0, length - i);
        }
        return formatted;
      };
    }
  ]);
  bitcoinApp.filter('timeSince', function () {
    return function (timestamp) {
      var now;
      now = moment.unix();
      if (timestamp > now) {
        return 'just now';
      }
      return moment.unix(timestamp).fromNow().replace('a few seconds ago', 'just now');
    };
  });
  bitcoinApp.filter('suffix', function () {
    return function (value, suffix, includeZero) {
      if (includeZero == null) {
        includeZero = true;
      }
      if (value != null && value !== '' && (value !== 0 || includeZero)) {
        return value + suffix;
      } else {
        return '';
      }
    };
  });
  bitcoinApp.filter('prefix', function () {
    return function (value, prefix, includeZero) {
      if (includeZero == null) {
        includeZero = true;
      }
      if (value != null && value !== '' && (value !== 0 || includeZero)) {
        return prefix + value;
      } else {
        return '';
      }
    };
  });
  bitcoinApp.filter('rejectPercent', function () {
    return function (counts) {
      var rejected;
      rejected = 0;
      if (counts.shares !== 0) {
        rejected = (100 * counts.rejected / counts.shares).toFixed(1);
      }
      return '' + rejected + '%';
    };
  });
  bitcoinApp.filter('prettyJson', function () {
    return function (obj) {
      return JSON.stringify(obj, null, 2);
    };
  });
  bitcoinApp.factory('authentication', [
    '$http',
    '$rootScope',
    '$cookieStore',
    function ($http, $rootScope, $cookieStore) {
      var authenticated, changeAuthenticated;
      authenticated = $cookieStore.get('authenticated') || false;
      changeAuthenticated = function (newValue) {
        if (authenticated === !newValue) {
          authenticated = newValue;
          return $rootScope.$broadcast('authenticationChanged');
        }
      };
      return {
        isAuthenticated: function () {
          return authenticated;
        },
        login: function (username, password, rememberMe, success, error) {
          return $http.post('/login', {
            username: username,
            password: password,
            rememberMe: rememberMe
          }).success(function (response) {
            if (response.success) {
              changeAuthenticated(true);
              if (typeof success === 'function') {
                success();
              }
            } else {
              error(response.error);
            }
          }).error(function () {
            if (typeof error === 'function') {
              error();
            }
          });
        },
        logout: function (success, error) {
          return $http.post('/logout').success(function () {
            changeAuthenticated(false);
            return typeof success === 'function' ? success() : void 0;
          }).error(error);
        }
      };
    }
  ]);
  bitcoinApp.factory('miningStats', [
    '$http',
    '$q',
    '$resource',
    function ($http, $q, $resource) {
      var chart, summary;
      summary = $resource('/mining/summary');
      chart = $resource('/mining/chart');
      return {
        getSummary: function () {
          return summary.get();
        },
        getChart: function () {
          return chart.get();
        }
      };
    }
  ]);
  bitcoinApp.factory('pools', [
    '$resource',
    function ($resource) {
      var resource;
      resource = $resource('/pools/:id', { id: '@id' }, {
        'delete': {
          method: 'DELETE',
          params: { id: '@id' }
        }
      });
      return {
        getAll: function () {
          return resource.query();
        },
        get: function (id) {
          return resource.get({ id: id });
        },
        save: function (pool) {
          return pool.$save();
        },
        'delete': function (id) {
          return resource['delete']({ id: id });
        }
      };
    }
  ]);
  bitcoinApp.factory('popups', [
    '$dialog',
    function ($dialog) {
      return {
        messageBox: function (title, message, buttons) {
          return $dialog.dialog({
            templateUrl: '/templates/messageBox.html',
            controller: 'MessageBoxCtrl',
            resolve: {
              model: function () {
                return {
                  title: title,
                  message: message,
                  buttons: buttons
                };
              }
            }
          });
        },
        changeLabel: function (address, label) {
          return $dialog.dialog({
            templateUrl: '/templates/changeLabel.html',
            controller: 'ChangeLabelCtrl',
            resolve: {
              model: function () {
                return {
                  address: address,
                  label: label
                };
              }
            }
          });
        },
        newAddress: function () {
          return $dialog.dialog({
            templateUrl: '/templates/newAddress.html',
            controller: 'NewAddressCtrl'
          });
        },
        showAddress: function (address, label) {
          return $dialog.dialog({
            templateUrl: '/templates/newAddress.html',
            controller: 'ShowAddressCtrl',
            resolve: {
              model: function () {
                return {
                  address: address,
                  label: label
                };
              }
            }
          });
        }
      };
    }
  ]);
  bitcoinApp.factory('socket', [
    '$rootScope',
    function ($rootScope) {
      var socket;
      socket = io.connect();
      return {
        on: function (eventName, callback) {
          return socket.on(eventName, function () {
            var args;
            args = arguments;
            return $rootScope.$apply(function () {
              return callback.apply(socket, args);
            });
          });
        },
        emit: function (eventName, data, callback) {
          return socket.emit(eventName, data, function () {
            var args;
            args = arguments;
            return $rootScope.$apply(function () {
              if (callback) {
                return callback.apply(socket, args);
              }
            });
          });
        },
        removeAllListeners: function () {
          return socket.removeAllListeners();
        }
      };
    }
  ]);
  bitcoinApp.factory('walletInfo', [
    '$resource',
    '$http',
    '$q',
    function ($resource, $http, $q) {
      var addresses, price, recipients, summary;
      summary = $resource('/wallet/summary');
      price = $resource('/wallet/price');
      recipients = $resource('/wallet/recentRecipients', {}, {
        'get': {
          method: 'GET',
          isArray: true
        }
      });
      addresses = $resource('/wallet/addresses');
      return {
        getSummary: function (num) {
          return summary.get({ show: num });
        },
        getPrice: function () {
          return price.get();
        },
        getRecentRecipients: function () {
          return recipients.get();
        },
        getAddresses: function () {
          return addresses.query();
        },
        newAddress: function (label) {
          var deferred;
          deferred = $q.defer();
          $http.post('/wallet/newaddress', { label: label }).success(function (address) {
            return deferred.resolve(address);
          }).error(function () {
            return deferred.reject();
          });
          return deferred.promise;
        },
        sendTx: function (tx) {
          var deferred;
          deferred = $q.defer();
          $http({
            method: 'POST',
            url: '/wallet/send',
            data: tx
          }).success(function () {
            return deferred.resolve();
          }).error(function (data, status) {
            return deferred.reject(data.error);
          });
          return deferred.promise;
        },
        signMsg: function (msg) {
          var deferred;
          deferred = $q.defer();
          $http({
            method: 'POST',
            url: '/wallet/sign',
            data: msg
          }).success(function (data) {
            return deferred.resolve(data.signature);
          }).error(function (data, status) {
            return deferred.reject(data.error);
          });
          return deferred.promise;
        }
      };
    }
  ]);
}.call(this));