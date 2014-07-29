###
  A repeating interval generator class
    
    only works on same day but the date pattern changes
    
    
    This generates a series of time interval object based upon
    a schedule
    
    these are generated on a daily basis
    
###


# the repeating interval class just visualiuses a series
# of time slots
class @RepeatingInterval
  
  
  next: -> throw Error "unimplemented method"
  interval: -> throw Error "unimplemented method"
  
  # these are the generator classes
  # so these are used to generate sequences of intervals
  class BaseInterval
    # default is midnight
    # default is a whole day 00:00 -> 23:59:59
    constructor: (@_time, @_lengthseconds, @_hour, @_minute=0, @_second=0) ->
    
    # get the repeating interval method
    interval: -> throw Error "unimplemented method"
    # this is a delegate method to the generator
    next: -> throw Error "unimplemented method"
    
    # set the lentgh
    setSeconds: (seconds) -> @setMilliseconds(seconds*1000)
    setMinutes: (minutes) -> @setSeconds(minutes*60)
    setHours: (hours) -> @setMinutes(hours*60)
    
  # constructor takes a mydate object
  # work out interval that falls on time or next
    
  class @Daily extends BaseInterval
    # this handles multiple days per week
    # sunday, tuesday, wednesday
    # or all 7 days
    # this is a single day of month
    # from current one work out the next instance
    constructor: ->
    
    # this is the generator class which returns 
    class DailyRepeatingInterval extends RepeatingInterval
    
  class @MonthlyDate extends BaseInterval
    # this is the 1st of the month regarless of date
    # from current one work out next instance
    class MonthlyDateRepeatingInterval extends RepeatingInterval
    
    
  class @MonthlyDay extends BaseInterval
    # this handles day of month
    # 1st sunday of month
    # from current one work out next instance
    class MonthlyDateRepeatingInterval extends RepeatingInterval
