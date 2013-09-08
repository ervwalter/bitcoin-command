_ = require('underscore')

_.mixin toDictionary: (arr, key) ->
    throw new Error('_.toDictionary takes an Array') unless _.isArray arr
    _.reduce arr, (dict, obj) ->
        k = key?(obj)
        unless k
            return dict unless obj[key]?
            k = obj[key]
        dict[k] = obj
        return dict
    , {}

module.exports = _