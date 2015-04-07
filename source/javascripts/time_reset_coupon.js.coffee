class ResetCoupon
  constructor: (data = {}, @node) ->
    # make it reset at midnight every day by default
    @interval = RepeatingIntervalGenerator.generate(_.extend {type: "everyday", hour:0, minute:0}, data, {length: 0, allday: 0, times: 1})[0]
    @period = @interval.prev().getStart() # get the start of the previous period
    # @next_period = interval.getStart() # this is the time to start the next interval
    # filter this by date number of records is the box count

  isRedeemed: ->
    !!_.find @node.getNodeData(), (v) =>
      d = new Date(v.get("updated_at"))
      d.valueOf() > @period.valueOf()


RepeatingIntervalGenerator =
  generate: (spec) ->
    # initialize one of the time based classes
    gen = (spec={}, kls) ->
      o = new kls()
      unless spec.allday=="1"
        o.setMinutes(spec.length) if spec.length?
        o.setStartTime(spec.hour, spec.minute) if spec.hour? and spec.minute?
      o
    filterArray = (array) ->
      Number(x) for x in array when x isnt ""
    makeArray = (spec, generator) ->
      # generator = generator.interval()
      # # if the current start time - the leeway (rewind time) is less than current time add it in
      # if (generator.getStart().valueOf() - (spec.leeway_before*60*1000)) < new Date().valueOf()
      # if spec.generate_extra=="1"
      # intervals.push generator
      # 1st interval? do checks
      generator = generator.interval()
      intervals = for x in [0..Number(spec.times)]
        int = generator # interval is actually the current one
        generator = generator.next()
        int
      # if the 1st interval falls within the leeway time
      # and generate
      if (intervals[0].getStart().valueOf() - (spec.leeway_before*60*1000)) < new Date().valueOf()
        unless spec.generate_extra=="1"
          intervals[1...]
        else
          intervals
      else
        # chop the end off
        intervals[...-1]

    switch spec.type
      when "everyday"
        o = gen(spec, RepeatingInterval.EveryDay)
        # has no options
        makeArray(spec, o)
      when "weekly"
      # initialize basic properties
        o = gen(spec, RepeatingInterval.Daily)
        # setup specific propertities
        o.setDays(filterArray(spec.week_days))
        makeArray(spec, o)
      when "monthly"
      # initialize basic properties
        o = gen(spec, RepeatingInterval.MonthlyDate)
        # setup specific propertities
        o.setDates(filterArray(spec.month_dates))
        makeArray(spec, o)
      when "monthly_day"
      # initialize basic properties
        o = gen(spec, RepeatingInterval.MonthlyDay)
        # setup specific propertities
        weeks = for x in spec.month_days when x isnt ""
          # day week use regexps to split out
          [day, week] = x.split ","
          [Number(week), Number(day)]
        o.setDayWeeks weeks...
        makeArray(spec, o)
      when "duration_days"
        o = gen({}, RepeatingInterval.NumberOfDays)
        o.setDays Number(spec.days) if spec.days isnt ""
        # return single interval
        [o.interval()]
      else
        throw Error "Unknown type #{spec.type}!"

###
  A time interval
  Declared as a length and start forumula

###
class TimeInterval
  # has start / end
  # has start / duration
  lpad = (number, length=2, pad="0") ->
    n = "#{number}"
    n = "#{pad}#{n}" while n.length < length
    n
  # break a time into HH:MM:SS:MS am/pm
  formatTime = (date) ->
    # 12:45am ->0,1
    # 12:45pm ->12,1
    hours = date.getHours()%12
    hours = 12 if hours == 0
    hour: "#{hours}"
    minute: lpad(date.getMinutes())
    second:lpad(date.getSeconds())
    millisecond:lpad(date.getMilliseconds(),3)
    ampm: if date.getHours() < 12 then "am" else "pm"
  constructor: (options={}) ->
    for opt in ["start", "end"]
      @[opt] = new Date(options[opt]) if options[opt]?
  setStart: (start) ->
    @start = new Date(start.valueOf?() ? start)
  setEnd: (end) ->
    @end = new Date(end.valueOf?() ? end)
  # make clones of the date objects
  getStart: -> new Date(@start.valueOf())
  getEnd: -> new Date(@end.valueOf())
  getLength: -> @getEnd().valueOf() - @getStart().valueOf()
  isWithinInterval: (date = new Date()) ->
    @getEnd().valueOf() > date.valueOf() >= @getStart().valueOf()
  isSameDay: -> @valuesSame "Date", "Month", "FullYear"
  # check if a bunch of values are the same
  valuesSame: (values...) ->
    for value in values
      return false unless @getStart()["get#{value}"]() == @getEnd()["get#{value}"]()
    true
  equals: (interval) ->
    @getStart().valueOf?()==interval?.getStart().valueOf?() and @getEnd().valueOf?()==interval?.getEnd().valueOf?()
  toString: ->
    start = formatTime @getStart()
    end = formatTime @getEnd()
    minute = (spec) ->
      if spec.minute == "00"
        ""
      else
        ":#{spec.minute}"
    hour = (spec, end=null) ->
      if spec.hour=="12" and spec.minute=="00"
        if spec.ampm == "am"
          "midnight"
        else
          "midday"
      else
        # check if end spec am/pm matches leave off
        ampm = unless end?.ampm == spec.ampm
          spec.ampm
        else
          ""
        "#{spec.hour}#{minute(spec)}#{ampm}"
    if @isSameDay()
      if @valuesSame "Hours", "Minutes"
        "#{@getStart().toDateString()} #{hour(end)}"
      else
        "#{@getStart().toDateString()} #{hour(start,end)}-#{hour(end)}"
    else
      "#{@getStart().toDateString()} #{hour(start)}-#{@getEnd().toDateString()} #{hour(end)}"
  toJSON: ->
    start: @getStart()
    end: @getEnd()

###
  A repeating interval generator class

    only works on same day but the date pattern changes


    This generates a series of time interval object based upon
    a schedule

    these are generated on a daily basis

###


# the repeating interval class just visualiuses a series
# of time slots
class RepeatingInterval extends TimeInterval

  #utility method to get the number of days in the month given by the date passed in
  _daysInMonth = (date) ->
    # go to next month and go back 1 day (0th date)
    new Date(date.getFullYear(), date.getMonth()+1, 0).getDate()
  _dateAdjust = (date, offsetMs) ->
    # compensate for crossing DST boundries
#    d = "#{date}, #{offsetMs/1000/60*60}"
    tz = date.getTimezoneOffset()
    newDate = new Date(date.getTime() + offsetMs)
    adjust = tz - newDate.getTimezoneOffset()
    if adjust != 0
      newDate.setTime newDate.getTime() - (1000*60*adjust) # adjust for DST
    #      console.log "BEFORE:#{d}, AFTER:#{newDate}"
    newDate
  constructor: (@spec, @starttime) ->
    # work out the next interval based upon the spec
    # keep adding 1 day to starttime until the day matches one of the array values
    # then set the start time approiapetly
    # compare to starttime if greater than start time it's good
    # start the loop off
    start = new Date(@starttime.valueOf()) # use the end date
    # adjust date first
    start = _dateAdjust(start, -1000*24*60*60 * @constructor.scandays)
    # then reset time bits
    start = @spec._resetTime(start)
    # rewind 7 days and set the correct start time
    #    console.log "START", start, @starttime
    # use greater than or equals here this is MILLISECONDS resolution here
    until (start.valueOf()+@spec.getLength()) > @starttime.valueOf() and @_validDate(start)
      start = _dateAdjust(start, 1000*24*60*60)
    #      console.log "CHECK DATE", start
    @setStart start
    @setEnd _dateAdjust(start, @spec.getLength())
#    console.log "END: #{@getEnd()}"
  next: ->
    throw Error "unimplemented method" unless @spec.constructor.intervalClass
    # creep it forward 1 ms to move out of current range
    new @spec.constructor.intervalClass(@spec, new Date(@getEnd().valueOf()+1))

  # the supplied interval ENDS before the START of this interval
  prev: ->
    # keep going back 1 day at a time until the next() == this
    # that object is then the previous interval return it
    searchStart = @getStart()
    interval = @
    counter = 0
    #console.log "INTERVAL IS #{@}"
    # start of this interval is < than the end of the following interval
    #@getStart().valueOf?()==interval?.getStart().valueOf?() and @getEnd().valueOf?()==interval?.getEnd().valueOf?()

    until @equals n=interval.next()
      searchStart = _dateAdjust(searchStart, -1000*24*60*60)
      #searchStart.setUTCDate searchStart.getUTCDate() - 1
      interval = new @spec.constructor.intervalClass(@spec, searchStart.valueOf())
      #      console.log "#{@}"
      #      console.log "DATE: #{searchStart} INT: #{interval} NEXT:#{n} EQ: #{@equals n}"
      #console.log "NEXT:#{n.getStart().valueOf()-@getStart().valueOf()}-#{n.getEnd().valueOf()-@getEnd().valueOf()} THIS:#{interval.getStart().valueOf()}-#{interval.getEnd().valueOf()}"
      if ++counter > 120 # days
        throw Error "Infinite loop tried #{counter} times!"
    interval

  # interval just return self
  interval: -> @

  isWithinStart: ->
    @isWithinInterval(@spec.startTime)

  # these are the generator classes
  # so these are used to generate sequences of intervals
  class BaseInterval


    # default is midnight
    # default is a whole day 00:00 -> 23:59:59
    # get the repeating interval method

    _intervalNames = ['hour', 'minute', 'second', 'millisecond']

    # default length is 1 day
    length: 60*60*1000*24 - 1 # 1 hour * milliseconds * 1 day
    hour: 0
    minute: 0
    second: 0
    millisecond: 0

    constructor: (@startTime = new Date()) ->

    interval: ->
      throw Error "interval generator is not implemented" unless @constructor.intervalClass
      new @constructor.intervalClass(@, @startTime)

    # this is a delegate method to the generator
    next: -> @interval().next()
    prev: -> @interval().prev()
    equals: (interval) -> @interval().equals(interval)
    getStart: -> @interval().getStart()
    getEnd: -> @interval().getEnd()

    setMilliseconds: (ms) ->
      if ms > 7 * 24 * 60 * 60 * 1000 - 1
        throw Error "Length of interval can not be more than 1 week"
      if ms < 0
        throw Error "Interval can not be negative"
      @length = ms
      # return this
      @
    # set the length - note these override the length
    setSeconds: (seconds) ->@setMilliseconds(seconds*1000)
    setMinutes: (minutes) -> @setSeconds(minutes*60)
    setHours: (hours) -> @setMinutes(hours*60)
    getLength: -> @length
    # set the start time in hour, minute, second, millisecond
    # defaults to 0 if left off
    setStartTime: (startTime...) ->
      startTime = _.flatten(startTime)
      for val, i in startTime
        @[_intervalNames[i]] = val

    # reset a date to the starttime given
    _resetTime: (date) ->
      #new Date(date.getYear(), date.getMonth(), date.getDate(), 1*@hour, 1*@minute, 1*@second, 1*@millisecond)
      #      date.setHours @hour
      #      date.setMinutes @minute
      #      date.setSeconds @second
      #      date.setMilliseconds @millisecond
      # get midnight on the day in question
      day = new Date(date.getFullYear(), date.getMonth(), date.getDate())
      tz = day.getTimezoneOffset()
      hour = day.getHours()
      if hour != 0
        if hour > 12
          day.setTime(day.getTime() + (1000*60*60*(24-hour)))
        else
          day.setTime(day.getTime() - (1000*60*60*hour))
      newDate = new Date(day.getTime() + 1000*60*60*@hour + 1000*60*@minute + 1000*@second + 1*@millisecond)
      adjust = tz - newDate.getTimezoneOffset()
      if adjust != 0
        newDate.setTime newDate.getTime() - (1000*60*adjust) # adjust for DST
      newDate
  # constructor takes a mydate object
  # work out interval that falls on time or next

  class @Daily extends BaseInterval

    _validDays = [0..6]

    # this handles multiple days per week
    # sunday, tuesday, wednesday
    # or all 7 days
    # this is a single day of month
    # from current one work out the next instance
    days: _validDays

    # set the repeating days, By default every day
    setDays: (days...) ->
      days = _.flatten(days)
      unless _.every(days, (v) -> _.contains(_validDays, v))
        throw Error "Days must be between 0 and 6"
      if days.length == 0
        throw Error "Must set at least 1 day"
      @days = _.chain(days).uniq().sort().value()
      @
    # this is the generator class which returns
    class DailyRepeatingInterval extends RepeatingInterval
      @scandays: 7
      _validDate: (date) ->
        # is the day of this date one of our target days
        _.indexOf(@spec.days, date.getDay(), true) != -1

    @intervalClass: DailyRepeatingInterval
  class @EveryDay extends @Daily
    setDays: -> # null function
  class @MonthlyDate extends BaseInterval
    # this is the 1st of the month regarless of date
    # from current one work out next instance
    _validDates = (x for x in [-3..31] when x isnt 0)

    # every day is valid
    dates: _validDates
    setDates: (dates...) ->
      dates = _.flatten(dates)
      unless _.every(dates, (v) -> _.contains(_validDates, v))
        throw Error "Days must be between 0 and 6"
      if dates.length == 0
        throw Error "Must set at least 1 day"
      @dates = _.chain(dates).uniq().sort().value()
      @

    class MonthlyDateRepeatingInterval extends RepeatingInterval
      @scandays: 1
      _validDate: (date) ->
        # convert -ve dates into actual date values
        # -1 means last day of month etc...
        daysInMonth = _daysInMonth(date)
        # convert the dates
        dates = for v in @spec.dates
          if v < 0
            v = (daysInMonth+1) + v # ie if 28 then 28+1 + -1 = 28
          v
        # is the day of this date one of our target days
        _.indexOf(dates, date.getDate()) != -1
    #next is simply myself combined with the end interval

    # save a reference to this class on the class itself to be reused by the parent classes
    @intervalClass: MonthlyDateRepeatingInterval

  class @MonthlyDay extends BaseInterval
    _validWeeks = (x for x in [-2..5] when x isnt 0)
    _validDays = [0..6]

    # default is 2nd last Sunday of the month
    # week number is first followed by the day number
    dayWeeks: [[_validWeeks[0], _validDays[0]]]

    setDayWeeks: (ranges...) ->
      throw Error "Need at least 1 range" unless ranges.length > 0
      # check values
      for range in ranges
        throw Error "Need 2 values" unless range.length == 2
        throw Error "Week out of range -2->5 except 0 required got #{range[0]}" unless _.indexOf(_validWeeks, range[0], true) != -1
        throw Error "Day out of range 0-6 got #{range[1]}" unless _.indexOf(_validDays, range[1], true) != -1
      @dayWeeks = ranges
    # this handles day of month
    # 1st sunday of month
    # from current one work out next instance
    class MonthlyDateRepeatingInterval extends RepeatingInterval
      @scandays: 7
      # quick method to get the number of days in the given month given by date
      _validDate: (date) ->
        # convert -ve dates into actual date values
        # -1 means last day of month etc...
        # used for negative calculations
        daysInMonth = _daysInMonth(date)
        # convert the dates
        for dayWeek in @spec.dayWeeks
          # return true on first match
          if (date.getDay() == dayWeek[1] and
            if dayWeek[0] < 0 # -ve value
              (daysInMonth - date.getDate())//7 == (-1 * dayWeek[0]) - 1
            else
              (date.getDate()-1)//7 == (dayWeek[0]-1))
            # day and week needs to match
            # if week is -ve then need to work from length of month
            return true
        false

    @intervalClass: MonthlyDateRepeatingInterval

  # simple number of days generator
  class @NumberOfDays extends BaseInterval

    days: 1
    setDays: (@days) ->

    class NumberOfDaysRepeatingInterval extends RepeatingInterval
      constructor: (@spec, @starttime) ->
        @setStart new Date(@starttime.valueOf())
        end = new Date(@starttime.valueOf())
        end.setDate end.getDate() + @spec.days
        end.setMinutes 59
        end.setHours 23
        end.setSeconds 59
        end.setMilliseconds 999
        @setEnd end
      prev: ->
        throw Error "Not Implemented"
    @intervalClass: NumberOfDaysRepeatingInterval


@RepeatingIntervalGenerator = RepeatingIntervalGenerator
@RepeatingInterval = RepeatingInterval
@TimeInterval = TimeInterval
@ResetCoupon = ResetCoupon