# the gernator for repeating intervals

describe "Repeating Interval gernator", ->
  beforeEach ->
    @realDate = Date
    @gen = RepeatingIntervalGenerator
    @clock = jasmine.clock().install()
    @clock.mockDate(new Date(2014,0,2,16,30))
  afterEach ->
    jasmine.clock().uninstall()
  it "has a fake clock that works", ->
    expect(new Date()).toEqual new @realDate(2014,0,2,16,30)
  # quick 'n' dirty function to convert all values to stirngs
  convert = (d) ->
    if _.isArray(d)
      convert(v) for v in d    
    else if _.isObject(d)
      o = {}
      for key, value of d
        o["#{key}"] = convert(value)
      o
    else
      "#{d}"
  describe "Conversion Function to strings", ->
    it "converts everything to strings", ->
      original = 
        a: "test"
        b: ["", 1,2]
        c: true
        d:
          e: 1
      strings =
        "a": "test"
        "b": ["", "1", "2"]
        "c": "true"
        "d":
          "e": "1"
      expect(convert(original)).toEqual strings
  
  describe "Weekly function", ->
    it "generates 2 dates", ->
      # date is Jan 2 2014
      d = data.weekly()
      d.generate_extra = "0"
      @clock.mockDate(new Date(2014,0,4,16,30))
      expect(new Date()).toEqualDate 4,1,2014
      expect(new Date()).toEqualTime 16,30
      intervals = @gen.generate(d)
      expect(intervals.length).toEqual 2
      expect(intervals[0]).toEqualInterval 180*60*1000, 5,1,2014, 17
      expect(intervals[1]).toEqualInterval 180*60*1000, 6,1,2014, 17
    it "generates 2 dates skipping first date 59 min in", ->
      # date is Jan 2 2014
      d = data.weekly()
      d.generate_extra = "0"
      @clock.mockDate(new Date(2014,0,5,16,1))
      expect(new Date()).toEqualDate 5,1,2014
      expect(new Date()).toEqualTime 16,1
      intervals = @gen.generate(d)
      expect(intervals.length).toEqual 2
      expect(intervals[0]).toEqualInterval 180*60*1000, 6,1,2014, 17
      expect(intervals[1]).toEqualInterval 180*60*1000, 7,1,2014, 17
    it "generates 2 dates skipping first date in period", ->
      # date is Jan 2 2014
      d = data.weekly()
      d.generate_extra = "0"
      @clock.mockDate(new Date(2014,0,5,19,59))
      expect(new Date()).toEqualDate 5,1,2014
      expect(new Date()).toEqualTime 19,59
      intervals = @gen.generate(d)
      expect(intervals.length).toEqual 2
      expect(intervals[0]).toEqualInterval 180*60*1000, 6,1,2014, 17
      expect(intervals[1]).toEqualInterval 180*60*1000, 7,1,2014, 17
  # type day, date, monthday, numberofdays
  # repeat if less than X hours left in period?
  data =
    "type": "xxx" # one of these types
    # control the days
    "days": # for the repeating day/month/month type 
    # values for this depend on the type
    # for the duration it's simply a text box of days and not a multiple select (ie array)
    # for month day it's DAY,WEEK as a string ie "0,-1" Last sunday of Month
    # for month it's simply the date
      ["", "1", "2"]
    # length of time options (only for the first 3 options)
    "allday": "1" # overwrite the hour, minute,length thing
    "hour" : "17"  # start at 5pm
    "minute" : "00"
    "length": "180" # 180 minutes (3 hours)
    # contol the number of slots generated"
    "times": "1" # eg 5
    # control the leeway if applicable if generated within x minutes of starting and before the end
    ###
      description of leeway
      
      if the first event begins within X minutes of the current time - or it's already happening
      then skip it's generation and start counting from the next event
      
      There is a boolean flag which will cause this event to be generated regardless
      generate extra: when true and within leeway 
      
    ###
    leeway_before: 60
    generate_extra: 1
    
  data = 
    weekly: ->
      convert
        type: "weekly"
        days: ["",0,1,2] # sun, mon, tuesday
        allday: 0
        hour: 17
        minute: 0
        length: 180
        times: 2
        leeway_before: 60
        generate_extra: 1
    monthly: ->
      convert
        type: "monthly"
        days: ["",-1,15] # last and 15th
        allday: 0
        hour: 17
        minute: 0
        length: 180
        times: 2
        leeway_before: 60
        generate_extra: 1
    monthly_day: ->
      convert
        type: "monthly_day"
        days: ["","0,-1","2,2"] #last Sunday(-1,0) and 2nd Tuesday(2,2) 
        allday: 0
        hour: 17
        minute: 0
        length: 180
        times: 2
        leeway_before: 60
        generate_extra: 1 # generate extra if date falls on day
    duration: ->
      convert
        type: "duration_days"
        days: 15 # 15 days 
        allday: 0 # ignored
        hour: 17 #ignored
        minute: 0 #ignored
        length: 180 # ignored
        times: 2 #ignored
        leeway_before: 60 #ignored
        generate_extra: 1 #ignored
