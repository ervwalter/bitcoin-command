###
  Dashboard Controller
###

bitcoinApp.controller 'DashboardCtrl', ($scope, $timeout, miningStats, walletInfo, authentication, socket, safeIdFilter) ->
    $scope.authenticated = authentication.isAuthenticated()

    $scope.mining = miningStats.getSummary()
    $scope.wallet = walletInfo.getSummary(5)
    $scope.price = walletInfo.getPrice()

    updateMiningSummary = -> $scope.mining.$get()
    updatePrice = -> $scope.price.$get()
    updateWallet = -> $scope.wallet.$get({show: 5})

    Highcharts.setOptions global: useUTC: false
    chartConfig = {
        chart:
            backgroundColor: '#f6f6f6'
            type: 'area'
            animation: true
        credits:
            enabled: false
        colors: [ '#4572a7', '#aa4643', '#80699b', '#3d96ae', '#db843d' ]
        plotOptions:
            area:
                fillOpacity: 0.5
                lineWidth: 1
            series:
                animation: false
                marker:
                    enabled: false
                stacking: 'normal'
        xAxis:
            type: 'datetime'
            tickInterval: 24 * 3600 * 1000
            gridLineWidth: 1
            endOnTick: false
        yAxis:
            min: 0
            showFirstLabel: false
            endOnTick: false
            title:
                text: null
            labels:
                formatter: ->
                    hashrateFilter this.value
        loading: true
        title:
            text: 'Hash Rate, Past 3 Days'
    }

    #$('#chart').highcharts(chartConfig)

    updateChart = ->
        miningStats.getChart().$promise.then (chartData) ->
            chartConfig.plotOptions.series.pointInterval = chartData.pointInterval
            chartConfig.plotOptions.series.pointStart = chartData.pointStart
            chartConfig.series = chartData.series
            chartConfig.loading = false
            $('#chart').highcharts()?.destroy()
            $('#chart').highcharts(chartConfig)
            return
    updateChart()

    socket.on 'share', (data) ->
        if $scope.mining.devices?
            poolId = "#pool-#{safeIdFilter(data.pool)}"
            deviceId = "#device-#{safeIdFilter(data.hostname + ':' + data.device)}"
            $(id).stop().clearQueue().fadeTo(0, 1).fadeTo(700,0) for id in [poolId, deviceId]
            device = _.find($scope.mining.devices[data.hostname], (d) -> d.device is data.device)
            pool = _.find($scope.mining.pools, (p) -> p.name is data.pool)
            if device? and pool?
                device.lastPool = data.pool
                device.lastShare = moment().unix()
                pool.lastShare = moment().unix()
            else
                console.log 'Detected new device/pool'
                updateMiningSummary()
                updateChart()

    # setup refresh intervals for all the pieces of data
    sixtySeconds = 60000
    oncePerMinute = $timeout(miningTimeout = ->
        updateMiningSummary()
        updateChart()
        updatePrice()
        oncePerMinute = $timeout(miningTimeout, sixtySeconds)
        return
    , sixtySeconds)

    tenSeconds = 10000
    oncePerTenSeconds = $timeout(walletTimeout = ->
        updateWallet()
        oncePerTenSeconds = $timeout(walletTimeout, tenSeconds)
        return
    , tenSeconds)

    $scope.$on '$destroy', ->
        socket.removeAllListeners()
        $timeout.cancel oncePerTenSeconds if oncePerTenSeconds
        $timeout.cancel oncePerMinute if oncePerMinute
