describe "RepeatingInterval", ->
  describe "Daily", ->
    beforeEach ->
      @i = new RepeatingInterval.Daily()
    describe "default start Date", ->
      # the default start date of the interval is 24 hours 
    it "default length", ->
      interval = @i.next()
      # expect length of interval to equal 1 hour
      expect(interval.getEnd().valueOf() - interval.getStart().valueOf()).toEqual 60*60*1000*24
      
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
        interval = @i.next()
        # expect length of interval to equal 1 hour
        expect(interval.getEnd().valueOf() - interval.getStart().valueOf()).toEqual 60*60*1000
