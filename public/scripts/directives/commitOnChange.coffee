bitcoinApp.directive 'commitOnChange', ($timeout) ->
    require: "ngModel"
    link: ($scope, $element, $attrs, modelCtrl) ->
        bufferedValue = undefined

        onChange = (e) ->
            $timeout flushViewValue

        bufferViewValue = (value) ->
            bufferedValue = value

        flushViewValue = ->
            $setViewValue.call modelCtrl, bufferedValue

        $setViewValue = modelCtrl.$setViewValue
        modelCtrl.$setViewValue = bufferViewValue

        $element.bind "change", onChange
