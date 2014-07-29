###

  Ideas for date object what it needs to do
  
  A) Find next/pervious date point based upon
    Given an aribtray date/time
    
    day of week - ie "next tuesday"
     - what happens when it's tuesday already?
     - use current time 
    day of month ie "5th of the month" (what about months with shorter dates?)    
    week within a month ie "2nd Tuesday"
    week with a month ie "2nd last Thursday"
    N days from now
    
    overload the time and date
    
    Is this object immutable? can the date be changed or does it return a new MyDate each time?
    or is it chainable? does each method modify the internal state of the objct but return a reference to this?
  
###
delegate = (klass, property, methods...) ->
  for m in methods
    do (m) ->
      klass::[m] = (args...) ->
        @[property][m](args...)
      return
  return

# setters return @ each time
delegate_setter = (klass, methods...) ->
  for m in methods
    do (m) -> klass::[m] = (args...) ->
      # clone the MyDate Class
      o = new klass(@date)
      # call the delegate method
      o.date[m](args...)
      o

class @MyDate
  # proxy some methods from date onto MyDate
  delegate @, 'date', 'getFullYear', 'getMonth', 'getDate', 'getHours', 'getMinutes', 'getSeconds', 'getMilliseconds', 'getTime', 'getDay'
  delegate_setter @, 'date', 'setFullYear', 'setMonth', 'setDate', 'setHours', 'setMinutes', 'setSeconds', 'setMilliseconds'
  
  @SUNDAY = 0
  @MONDAY = 1
  @TUESDAY = 2
  @WEDNESDAY = 3
  @THURSDAY = 4
  @FRIDAY = 5
  @SATURDAY = 6
  constructor: (args...) ->
    if _.isArray(args[0])
      args = args[0] # undo array
    @date = switch args.length
      when 0 then new Date()
      when 1
        # IE when passed in a date object seems to round off the milliseconds get it's primitiave value
        if _.isDate(args[0])
          new Date(args[0].valueOf())
        else
          new Date(args[0])
      when 2 then new Date(args[0],args[1])
      when 3 then new Date(args[0],args[1], args[2])
      when 4 then new Date(args[0],args[1], args[2], args[3])
      when 5 then new Date(args[0],args[1], args[2], args[3], args[4])
      when 6 then new Date(args[0],args[1], args[2], args[3], args[4], args[5])
      when 7 then new Date(args[0],args[1], args[2], args[3], args[4], args[5], args[6])
  # generate a date object based upon an array
  # this trick calls the constructor for the date object
  # @getDateObject: (a) ->
    # #create(Date, a)
    # d = new Date(0)
    # ar = ["FullYear", "Month", "Date", "Hours", "Minutes", "Seconds", "MilliSeconds"]
    # for val, i in a
      # Date.prototype["set#{ar[i]}"].call(d, val)
    # return d
    #new Date(a[0], a[1], a[2], a[3], a[4], a[5], a[6])
  # used to get array to change values
  getDateArray: ->
    #year, month, date[, hours[, minutes[, seconds[,ms]]]]
    [@getFullYear(), @getMonth(), @getDate(), @getHours(), @getMinutes(), @getSeconds(), @getMilliseconds()]
  
  # get next Tuesday/ Tuesday week etc...
  setNextDay: (day, skip=0) ->
    days = day - @getDay()
    # if moving backwards then add 7 days (skip 1 period)
    if days <= 0
      skip += 1
    days += 7*skip
    # return new Object with date set correctly
    @setDate @getDate() + days
