describe "RepeatingInterval", ->
  describe "Daily", ->
    beforeEach ->
      # wednesday 1st jan 2014 1am
      @i = new RepeatingInterval.Daily(new Date(2014,0,1))
    describe "EveryDay" , ->
      beforeEach ->
        @i = new RepeatingInterval.EveryDay(new Date(2014, 0,1))
      it "works for hours and time", ->
        @i.setHours 1
        @i.setStartTime 17
        interval = @i.interval()
        expect(interval.getStart()).toEqualDate(1,1,2014)
        expect(interval.next().getStart()).toEqualDate(2,1,2014)
        expect(interval.next().next().getStart()).toEqualDate(3,1,2014)
        expect(interval.next().next().next().getStart()).toEqualDate(4,1,2014)
        expect(interval.next().next().next().next().getStart()).toEqualDate(5,1,2014)
        expect(interval.next().next().next().next().next().getStart()).toEqualDate(6,1,2014)
        expect(interval.next().next().next().next().next().next().getStart()).toEqualDate(7,1,2014)
        expect(interval.next().next().next().next().next().next().next().getStart()).toEqualDate(8,1,2014)
      # 5th April is the dst date
      # problem in
      it "works for DST date DST OFF", ->
        # 5pm on dst date
        @i = new RepeatingInterval.EveryDay(new Date(2015, 3,4)) # rth April
        @i.setHours 1
        @i.setStartTime 17
        expect(@i.getStart()).toEqualDate(4,4,2015)
        expect(@i.getStart().getHours()).toEqual 17
        expect(@i.getEnd().getHours()).toEqual 18
        expect(@i.getStart()).toEqualTime 17,0,0,0
        expect(@i.getEnd()).toEqualTime 18,0,0,0
      it "works for prev on DST Dates  DST OFF", ->
        @i = new RepeatingInterval.EveryDay(new Date(2015, 3,5)) # 5th April
        @i.setHours 1
        @i.setStartTime 17
        interval = @i.interval()
        expect(interval.getStart()).toEqualDate(5,4,2015)
        expect(interval.prev().getStart()).toEqualDate(4,4,2015)
      it "works for DST date a week out  DST OFF", ->
        # 5pm on dst date
        @i = new RepeatingInterval.EveryDay(new Date(2015, 3,11)) # rth April
        @i.setHours 1
        @i.setStartTime 17
        expect(@i.getStart()).toEqualDate(11,4,2015)
        expect(@i.getStart().getHours()).toEqual 17
        expect(@i.getEnd().getHours()).toEqual 18
        expect(@i.getStart()).toEqualTime 17,0,0,0
        expect(@i.getEnd()).toEqualTime 18,0,0,0
      it "works for prev on DST Dates a week out  DST OFF", ->
        @i = new RepeatingInterval.EveryDay(new Date(2015, 3,12)) # 5th April
        @i.setHours 1
        @i.setStartTime 17
        interval = @i.interval()
        expect(interval.getStart()).toEqualDate(12,4,2015)
        expect(interval.prev().getStart()).toEqualDate(11,4,2015)
      # 4th October is the dst date
      # problem in
      it "works for DST date DST ON", ->
        # 5pm on dst date
        @i = new RepeatingInterval.EveryDay(new Date(2015, 9,3)) # 4th April
        @i.setHours 1
        @i.setStartTime 17
        expect(@i.getStart()).toEqualDate(3,10,2015)
        expect(@i.getStart().getHours()).toEqual 17
        expect(@i.getEnd().getHours()).toEqual 18
        expect(@i.getStart()).toEqualTime 17,0,0,0
        expect(@i.getEnd()).toEqualTime 18,0,0,0
      it "works for prev on DST Dates  DST ON", ->
        @i = new RepeatingInterval.EveryDay(new Date(1443880800000)) # 4th October (in safari this is midnight)
        @i.setHours 1
        @i.setStartTime 17
        interval = @i.interval()
        expect(interval.getStart()).toEqualDate(4,10,2015)
        expect(interval.prev().getStart()).toEqualDate(3,10,2015)
      it "works for DST date a week out  DST ON", ->
        # 5pm on dst date
        @i = new RepeatingInterval.EveryDay(new Date(2015, 9,10)) # rth April
        @i.setHours 1
        @i.setStartTime 17
        expect(@i.getStart()).toEqualDate(10,10,2015)
        expect(@i.getStart().getHours()).toEqual 17
        expect(@i.getEnd().getHours()).toEqual 18
        expect(@i.getStart()).toEqualTime 17,0,0,0
        expect(@i.getEnd()).toEqualTime 18,0,0,0
      it "works for prev on DST Dates a week out  DST ON", ->
        @i = new RepeatingInterval.EveryDay(new Date(2015, 9,11)) # 5th April
        @i.setHours 1
        @i.setStartTime 17
        interval = @i.interval()
        expect(interval.getStart()).toEqualDate(11,10,2015)
        expect(interval.prev().getStart()).toEqualDate(10,10,2015)
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
    it "works for prev()", ->
      @i.setDates -1
      interval = @i.interval()
      expect(interval.getStart()).toEqualDate 31,1,2014
      expect(interval.next().prev().getStart()).toEqualDate 31,1,2014
      expect(interval.next().getStart()).toEqualDate 28,2,2014
      expect(interval.next().prev().next().getStart()).toEqualDate 28,2,2014
      expect(interval.next().next().getStart()).toEqualDate 31,3,2014
      expect(interval.next().prev().prev().next().next().next().getStart()).toEqualDate 31,3,2014
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
    it "works for prev()", ->
      @i.setDayWeeks [-1, MyDate.MONDAY]
      interval = @i.interval()
      expect(interval.prev().next().getStart()).toEqualDate 27,1,2014
      expect(interval.prev().next().next().getStart()).toEqualDate 24,2,2014
      expect(interval.prev().next().next().next().prev().next().getStart()).toEqualDate 31,3,2014
      expect(interval.prev().next().next().next().prev().prev().next().next().next().getStart()).toEqualDate 28,4,2014
  describe "NumberOfDays", ->
    beforeEach ->
      @i = new RepeatingInterval.NumberOfDays(new Date(2014,0,1,11))
    it "generates 30 day intervals", ->
      @i.setDays 30
      interval = @i.interval()
      expect(interval.getStart()).toEqualDate 1,1,2014
      expect(interval.getStart()).toEqualTime 11,0,0,0
      expect(interval.getEnd()).toEqualDate 31,1,2014
      expect(interval.getEnd()).toEqualTime 23,59,59,999
      expect(interval.next().getStart()).toEqualDate 1,2,2014
      expect(interval.next().getStart()).toEqualTime 0,0,0,0
      expect(interval.next().getEnd()).toEqualDate 3,3,2014
      expect(interval.next().getEnd()).toEqualTime 23,59,59,999
    it "doesn't do prev()", ->
      @i.setDays 30
      interval = @i.interval()
      expect ->
          interval.prev()
        .toThrow Error "Not Implemented"
