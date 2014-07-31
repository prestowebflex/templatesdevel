###
  A repeating interval generator class
    
    only works on same day but the date pattern changes
    
    
    This generates a series of time interval object based upon
    a schedule
    
    these are generated on a daily basis
    
###


# the repeating interval class just visualiuses a series
# of time slots
class @RepeatingInterval extends TimeInterval
  
  #utility method to get the number of days in the month given by the date passed in
  _daysInMonth = (date) ->
    # go to next month and go back 1 day (0th date)
    new Date(date.getFullYear(), date.getMonth()+1, 0).getDate()

  constructor: (@spec, @starttime) ->
    # work out the next interval based upon the spec
    # keep adding 1 day to starttime until the day matches one of the array values
    # then set the start time approiapetly
    # compare to starttime if greater than start time it's good
    # start the loop off
    start = new Date(@starttime.valueOf()) # use the end date
    start = @spec._resetTime(start)
    # rewind 7 days and set the correct start time
    start.setDate start.getDate() - @constructor.scandays
    # use greater than or equals here this is MILLISECONDS resolution here
    until (start.valueOf()+@spec.getLength()) > @starttime.valueOf() and @_validDate(start)
      start.setDate start.getDate() + 1 # increment by 1 day
    @setStart start
    @setEnd new Date(start.valueOf() + @spec.getLength())

  next: ->
    throw Error "unimplemented method" unless @spec.intervalClass
    # creep it forward 1 ms to move out of current range
    new @spec.intervalClass(@spec, new Date(@getEnd().valueOf()+1))
  
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
      throw Error "interval generator is not implemented" unless @intervalClass
      new @intervalClass(@, @startTime)

    # this is a delegate method to the generator
    next: -> @interval().next()
    
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
      date.setHours @hour
      date.setMinutes @minute
      date.setSeconds @second
      date.setMilliseconds @millisecond
      date
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

    intervalClass: DailyRepeatingInterval
    
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
    intervalClass: MonthlyDateRepeatingInterval

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
        throw Error "Week out of range -2->5 expect 0 required" unless _.indexOf(_validWeeks, range[0], true) != -1
        throw Error "Day out of range 0-6" unless _.indexOf(_validDays, range[1], true) != -1
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

    intervalClass: MonthlyDateRepeatingInterval