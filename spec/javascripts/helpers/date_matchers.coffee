beforeEach ->
  jasmine.addMatchers
    toBeLength: ->
      compare: (interval, length) ->
        pass = (len = (interval.getEnd().valueOf() - interval.getStart().valueOf())) == length
        message = if pass
          "Interval is correct length"
        else
          "Interval is incorrect length #{len} expected #{length}"
        pass: pass, message: message
    # date matcher
    toEqualDate: ->
      compare: (actual, day, month, year) ->
        pass = actual.getDate() == day && actual.getMonth() == (month-1) && actual.getFullYear() == year
        message = if pass
          "#{actual} is on #{day}/#{month}/#{year}"
        else
          "#{actual} is not on #{day}/#{month}/#{year}"
        pass: pass, message: message
    # time matcher - specific to less specific
    toEqualTime: ->
      compare: (actual, time...) ->
        timeFunctions = ["getHours", "getMinutes", "getSeconds", "getMilliseconds"]
        pass = true
        for val, i in time
          pass = pass && actual[timeFunctions[i]]() == val
        message = if pass
          "#{actual} is on #{time}"
        else
          "#{actual} is not #{time.join(':')}"
        pass: pass, message: message
    test: ->
      compare: (actual, expected, o) ->
        r = pass: actual == expected
        r.message = "test #{actual}"
        r
