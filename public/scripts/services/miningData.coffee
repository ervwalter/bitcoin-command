###
    Mining Data Service
###

bitcoinApp.factory 'miningStats', ($http, $q, $resource) ->
    summary = $resource '/mining/summary'
    chart = $resource '/mining/chart'

    return {
        getSummary: -> summary.get()
        getChart: -> chart.get()
    }


