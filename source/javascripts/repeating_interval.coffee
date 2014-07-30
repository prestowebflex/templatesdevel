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
    
    _validDays = _.range 7

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
      constructor: (@spec, @starttime) ->
        # work out the next interval based upon the spec
        # keep adding 1 day to starttime until the day matches one of the array values
        # then set the start time approiapetly
        # compare to starttime if greater than start time it's good
        # start the loop off
        start = new Date(@starttime.valueOf()) # use the end date
        start = @spec._resetTime(start)
        # rewind 7 days and set the correct start time
        start.setDate start.getDate() - 7
        # use greater than or equals here this is MILLISECONDS resolution here
        until (start.valueOf()+@spec.getLength()) > @starttime.valueOf() and @_validDay(start)
          start.setDate start.getDate() + 1 # increment by 1 day
        @setStart start
        @setEnd new Date(start.valueOf() + @spec.getLength())
      _validDay: (date) ->
        # is the day of this date one of our target days
        _.indexOf(@spec.days, date.getDay(), true) != -1

    intervalClass: DailyRepeatingInterval
    
  class @MonthlyDate extends BaseInterval
    # this is the 1st of the month regarless of date
    # from current one work out next instance
    
    setDates: (dates...) ->
      dates = _.flatten(dates)
      unless _.every(days, (v) -> _.contains(_validDays, v))
        throw Error "Days must be between 0 and 6"
      if days.length == 0
        throw Error "Must set at least 1 day" 
      @days = _.chain(days).uniq().sort().value()
      @
      
    
    class MonthlyDateRepeatingInterval extends RepeatingInterval
      constructor: (@spec, @starttime) ->
        # work out the next interval based upon the spec
        # keep adding 1 day to starttime until the day matches one of the array values
        # then set the start time approiapetly
        # compare to starttime if greater than start time it's good
        # start the loop off
        start = new Date(@starttime.valueOf()) # use the end date
        start = @spec._resetTime(start)
        # rewind 1 days and set the correct start time - this makes no sense to have longer than 1 day
        start.setDate start.getDate() - 1
        # use greater than or equals here this is MILLISECONDS resolution here
        until (start.valueOf()+@spec.getLength()) > @starttime.valueOf() and @_validDate(start)
          start.setDate start.getDate() + 1 # increment by 1 day
        @setStart start
        @setEnd new Date(start.valueOf() + @spec.getLength())
      _validDate: (date) ->
        # is the day of this date one of our target days
        date.getDate() == @spec.date
      #next is simply myself combined with the end interval
      next: ->
        # creep it forward 1 ms to move out of current range
        new MonthlyRepeatingInterval(@spec, new Date(@getEnd().valueOf()+1))

  class @MonthlyDay extends BaseInterval
    # this handles day of month
    # 1st sunday of month
    # from current one work out next instance
    class MonthlyDateRepeatingInterval extends RepeatingInterval
