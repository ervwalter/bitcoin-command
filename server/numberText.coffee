exports.numberToText = (num) ->
    if num is 0
        "zero"
    else
        convert_millions num

convert_millions = (num) ->
    if num >= 1000000
        convert_millions(Math.floor(num / 1000000)) + " million " + convert_thousands(num % 1000000)
    else
        convert_thousands num

convert_thousands = (num) ->
    if num >= 1000
        convert_hundreds(Math.floor(num / 1000)) + " thousand " + convert_hundreds(num % 1000)
    else
        convert_hundreds num

convert_hundreds = (num) ->
    if num > 99
        ones[Math.floor(num / 100)] + " hundred " + convert_tens(num % 100)
    else
        convert_tens num

convert_tens = (num) ->
    if num < 10
        ones[num]
    else tens[Math.floor(num / 10)] + " " + ones[num % 10]  unless num >= 10 and num < 20

ones = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
teens = ["ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]

