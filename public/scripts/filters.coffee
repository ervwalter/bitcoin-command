hashrateFilter = null

bitcoinApp.filter 'archived', ->
    (array, archived = true) ->
        _.filter(array, (item) -> (item.archived ? false) == archived )

bitcoinApp.filter 'safeId', ->
    (input) ->
        CryptoJS.MD5(input).toString()

bitcoinApp.filter 'hashrate', ->
    hashrateFilter = (input) ->
        hashrate = Number(input)
        if isNaN(hashrate) or hashrate <= 0
            return "-"
        units = "MH"
        if hashrate >= 1000
            hashrate /= 1000
            units = "GH"
        if hashrate >= 1000
            hashrate /= 1000
            units = "TH"
        if hashrate >= 1000
            hashrate /= 1000
            units = "PH"
        hashrate = hashrate.toPrecision(3)
        return "#{hashrate} #{units}/s"

bitcoinApp.filter 'confirmationCount', (numberFilter) ->
    (transaction) ->
        if transaction.confirmed
            return '✓'
        else
            return numberFilter(transaction.confirmations, '0')

bitcoinApp.filter 'transactionDescription', ->
    (tx) ->
        msg = ''
        switch tx.category
            when 'receive'
                msg = if tx.account? then tx.account else tx.address
            when 'send'
                msg = 'to: '
                if tx.to? then msg += tx.to else msg += tx.address
                msg += " (#{tx.comment})" if tx.comment?
                msg += ", fee: #{tx.fee * -1}" if tx.fee < 0
            when 'generate', 'immature'
                msg += "#{tx.account}, " if tx.account?
                msg += "generated"
            else
                msg = 'unknown'
        return msg

bitcoinApp.filter 'bitcoin', (numberFilter) ->
    (amount) ->
        formatted = numberFilter(amount, 8)
        if formatted isnt ''
            i = 0
            length = formatted.length
            while i < 6
                break if formatted.substr(length - i - 1, 1) isnt '0'
                i++
            formatted = formatted.substr(0, length - i)
        return formatted

bitcoinApp.filter 'timeSince', ->
    (timestamp) ->
        now = moment.unix()
        return 'just now' if timestamp > now
        return moment.unix(timestamp).fromNow().replace('a few seconds ago', 'just now')

bitcoinApp.filter 'suffix', ->
    (value, suffix, includeZero = true) ->
        if value? and value isnt '' and (value != 0 or includeZero)
            return value + suffix
        else
            return ''

bitcoinApp.filter 'prefix', ->
    (value, prefix, includeZero = true) ->
        if value? and value isnt '' and (value != 0 or includeZero)
            return prefix + value
        else
            return ''

bitcoinApp.filter 'rejectPercent', ->
    (counts) ->
        rejected = 0
        rejected = (100 * counts.rejected / counts.shares).toFixed(1) if counts.shares != 0
        return "#{rejected}%"

bitcoinApp.filter 'prettyJson', ->
    (obj) ->
        JSON.stringify(obj, null, 2)