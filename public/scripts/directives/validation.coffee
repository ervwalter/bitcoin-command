getFieldValidationExpression = (formName, fieldName, attrs = null) ->
    fieldExpression = formName + "." + fieldName
    invalidExpression = "#{fieldExpression}.$invalid"
    dirtyExpression = "#{fieldExpression}.$dirty"
    watchExpression = "[#{invalidExpression},#{dirtyExpression}"
    if attrs?
        for key of attrs
            if attrs.hasOwnProperty(key) and key != 'for' and key != 'class' and key.substr(0,1) != '$'
                watchExpression += ",#{fieldExpression}.$error.#{key}"
    watchExpression += "]"
    watchExpression

bitcoinApp.filter 'validationFieldFlattener', ->
    (field) ->
        JSON.stringify [field.$invalid, field.$dirty, field.$error]

bitcoinApp.directive "controlGroup", ->
    restrict: "E"
    require: "^form"
    replace: true
    transclude: true
    template: "<div class=\"control-group\" ng-transclude></div>"
    link: ($scope, el, attrs, ctrl) ->
        formName = ctrl.$name
        fieldName = attrs["for"]
        watchExpression = getFieldValidationExpression(formName, fieldName)
        $scope.$watchCollection watchExpression, ->
            field = $scope[formName][fieldName]
            return if field.$pristine
            hasError = false
            errors = field.$error
            for error of errors
                if errors.hasOwnProperty(error)
                    if errors[error]
                        hasError = true
                        break
            if hasError
                el.addClass "error"
            else
                el.removeClass "error"

bitcoinApp.directive "validationMessage", ->
    restrict: "E"
    require: "^form"
    replace: true
    template: "<div class=\"help-block\"></div>"
    link: ($scope, el, attrs, ctrl) ->
        formName = ctrl.$name
        fieldName = attrs["for"]
        watchExpression = getFieldValidationExpression(formName, fieldName, attrs)
        $scope.$watchCollection watchExpression, ->
            field = $scope[formName][fieldName]
            show = field.$invalid and field.$dirty
            el.css "display", (if show then "" else "none")
            html = ""
            if show
                errors = field.$error
                for error of errors
                    if errors.hasOwnProperty(error)
                        if errors[error] and attrs[error]
                            html += "<span>" + attrs[error] + " </span>"
                            #break
            el.html html

bitcoinApp.directive "submitButton", ->
    restrict: "E"
    require: "^form"
    transclude: true
    replace: true
    template: "<button " + "type=\"submit\" " + "class=\"btn btn-success\" " + "ng-transclude>" + "</button>"
    link: ($scope, el, attrs, ctrl) ->
        watchExpression = ctrl.$name + ".$invalid"
        $scope.$watch watchExpression, (value) ->
            attrs.$set "disabled", !!value

bitcoinApp.directive "validSubmit", ->
    restrict: "A"
    require: 'form'
    link: ($scope, el, attrs, ctrl) ->
        $element = angular.element(el)

        # Add novalidate to the form element.
        attrs.$set "novalidate", "novalidate"

        $element.bind "submit", (e) ->
            e.preventDefault()

            # Remove the class pristine from all form elements.
            $element.find(".ng-pristine").removeClass "ng-pristine"

            # Get the form object.
            form = $scope[ctrl.$name]

            # Set all the fields to dirty and apply the changes on the scope so that
            # validation errors are shown on submit only.
            angular.forEach form, (formElement, fieldName) ->
                # If the fieldname starts with a '$' sign, it means it's an Angular
                # property or function. Skip those items.
                return  if fieldName[0] is "$"
                formElement.$pristine = false
                formElement.$dirty = true
                return

            # Do not continue if the form is invalid.
            if form.$invalid
                # Focus on the first field that is invalid.
                $element.find(".ng-invalid").first().focus()
                $scope.$apply()
                return false

            # From this point and below, we can assume that the form is valid.
            $scope.$eval attrs.validSubmit
            $scope.$apply()

