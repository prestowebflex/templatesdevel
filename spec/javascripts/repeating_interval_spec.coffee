describe "RepeatingInterval", ->
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

  describe "Monthly", ->
    beforeEach ->
      @i = new RepeatingInterval.MonthlyDate(new Date(2014,0,1))
    it "works for multiple dates", ->
      @i.setDates 1,2
      interval = @i.interval()
      expect(interval.getStart()).toEqualDate 1,1,2014
      expect(interval.next().getStart()).toEqualDate 2,1,2014
      expect(interval.next().next().getStart()).toEqualDate 1,2,2014
    it "works for -ve dates", ->
      @i.setDates -1
      interval = @i.interval()
      expect(interval.getStart()).toEqualDate 31,1,2014
      expect(interval.next().getStart()).toEqualDate 28,2,2014
      expect(interval.next().next().getStart()).toEqualDate 31,3,2014
      
  describe "MonthlyDay", ->
    beforeEach ->
      @i = new RepeatingInterval.MonthlyDay(new Date(2014,0,1))
    it "works for multiple dates / weeks", ->
      # first monday and 2nd Tuesday
      @i.setDayWeeks [1, MyDate.MONDAY],  [2, MyDate.TUESDAY]
      interval = @i.interval()
      expect(interval.getStart()).toEqualDate 6,1,2014
      expect(interval.next().getStart()).toEqualDate 14,1,2014
      expect(interval.next().next().getStart()).toEqualDate 3,2,2014
      expect(interval.next().next().next().getStart()).toEqualDate 11,2,2014
    it "works for -ve Weeks", ->
      @i.setDayWeeks [-1, MyDate.MONDAY]
      interval = @i.interval()
      expect(interval.getStart()).toEqualDate 27,1,2014
      expect(interval.next().getStart()).toEqualDate 24,2,2014
      expect(interval.next().next().getStart()).toEqualDate 31,3,2014
      expect(interval.next().next().next().getStart()).toEqualDate 28,4,2014
      
