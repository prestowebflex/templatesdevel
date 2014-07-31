beforeEach ->
  equalLength = (interval, length) ->
    (len = (interval.getEnd().valueOf() - interval.getStart().valueOf())) == length
  equalDate = (date, day, month, year) ->
    date.getDate() == day && date.getMonth() == (month-1) && date.getFullYear() == year
  equalTime = (date, time...) ->
    timeFunctions = ["getHours", "getMinutes", "getSeconds", "getMilliseconds"]
    pass = true
    for val, i in time
      pass = pass && date[timeFunctions[i]]() == val
  jasmine.addMatchers
    toEqualInterval: ->
      compare: (interval, lengthMs, day, month, year, time...) ->
        passLength = equalLength interval, lengthMs
        passStartDate = equalDate interval.getStart(), day, month, year
        # this should check off interval end time
        passEndDate = equalDate interval.getEnd(), day, month, year
        passStartTime = equalTime interval.getStart(), time...
        endTime = new Date interval.getStart().valueOf()
        endTime.setMilliseconds endTime.getMilliseconds + lengthMs
        passEndTime = interval.getEnd().valueOf() == endTime.valueOf()
        
        pass = passLength && passStartDate && passEndDate and passStartTime and passEndTime
        message = if pass
          "Interval is correct"
        else
          msg = "Interval incorrect"
          unless passLength
            msg += " Length should be #{lengthMs} was #{interval.getEnd().valueOf() - interval.getStart().valueOf()}"
          unless passStartDate
            msg += " Start Date should be #{day}/#{month}/#{year} was #{interval.getStart()}"
           #Length:#{passLength} StartDate:#{passStartDate} EndDate:#{passEndDate} StartTime:#{passStartTime} EndTime:#{passEndTime}"
          unless passEndDate
            msg += " End Date should be #{day}/#{month}/#{year} was #{interval.getEnd()}"
          unless passStartTime
            msg += " Start time should be #{time} was #{interval.getStart()}"
          msg
        pass: pass, message: message
    toBeLength: ->
      compare: (interval, length) ->
        pass = equalLength interval, length
        message = if pass
          "Interval is correct length"
        else
          "Interval is incorrect length #{len} expected #{length}"
        pass: pass, message: message
    # date matcher
    toEqualDate: ->
      compare: (actual, day, month, year) ->
        pass = equalDate actual, day, month, year
        message = if pass
          "#{actual} is on #{day}/#{month}/#{year}"
        else
          "#{actual} is not on #{day}/#{month}/#{year}"
        pass: pass, message: message
    # time matcher - specific to less specific
    toEqualTime: ->
      compare: (actual, time...) ->
        pass = equalTime actual, time...
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
