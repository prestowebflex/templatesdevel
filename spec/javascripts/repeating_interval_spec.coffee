describe "RepeatingInterval", ->
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
  describe "Daily", ->
    beforeEach ->
      # wednesday 1st jan 2014 1am
      @i = new RepeatingInterval.Daily(new Date(2014,0,1))
    describe "days of week", ->
      it "returns the current within the interval", ->
        @i = new RepeatingInterval.Daily(new Date(2014,0,1,1))
        @i.setDays MyDate.WEDNESDAY
        interval = @i.interval()
        expect(interval.isWithinStart()).toBeTruthy()
        expect(interval.getStart()).toEqualDate 1,1,2014
      it "works for Sunday", ->
        @i.setDays MyDate.SUNDAY
        interval = @i.interval()
        expect(interval.getStart()).toEqualDate 5,1,2014
        expect(interval.next().getStart()).toEqualDate 12,1,2014
        expect(interval.next().next().getStart()).toEqualDate 19,1,2014
      it "works for Tuesday, Thursday", ->
        @i.setDays MyDate.TUESDAY, MyDate.THURSDAY
        @i.setHours 1
        @i.setStartTime 17
        interval = @i.interval()
        expect(interval.getStart()).toEqualTime 17,0,0,0
        expect(interval.getEnd()).toEqualTime 18,0,0,0
        expect(interval.getStart()).toEqualDate 2,1,2014
        expect(interval.next().getStart()).toEqualDate 7,1,2014
        expect(interval.next().next().getStart()).toEqualDate 9,1,2014
    describe "everyDay", ->
      describe "default start Date", ->
        # the default start date of the interval is 24 hours 
      it "default length", ->
        # expect length of interval to equal 1 hour
        @interval = @i.interval()
        expect(@interval).toBeLength(60*60*1000*24 - 1)
      
      describe "Length", ->
        # check the length of the intervals to 1 hour
        it "Hours", ->
          @i.setHours 1
        it "minutes", ->
          @i.setMinutes 60
        it "seconds", ->
          @i.setSeconds 60*60
        it "milliseconds", ->
          @i.setMilliseconds 60*60*1000
        afterEach ->
          # get the next interval
          @interval = @i.interval()
          # expect length of interval to equal 1 hour
          expect(@interval).toBeLength(60*60*1000)
       afterEach ->
         expect(@interval.getStart()).toEqualTime 0,0,0,0
         expect(@interval.getStart()).toEqualDate 1,1,2014
         expect(@interval.getEnd()).toEqualDate 1,1,2014
