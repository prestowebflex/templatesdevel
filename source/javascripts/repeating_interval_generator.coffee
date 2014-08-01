# initialize one of the time based classes
gen = (spec, kls) ->
  o = new kls()
  unless spec.allday=="1"
    o.setMinutes(spec.length) if spec.length
    o.setStartTime(spec.hour, spec.minute) if spec.hour and spec.minute
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
@RepeatingIntervalGenerator =
  generate: (spec) ->
    switch spec.type
      when "weekly"
        # initialize basic properties
        o = gen(spec, RepeatingInterval.Daily)
        # setup specific propertities
        o.setDays(filterArray(spec.days))
        makeArray(spec, o)
      when "monthly"
        # initialize basic properties
        o = gen(spec, RepeatingInterval.MonthlyDate)
        # setup specific propertities
        o.setDates(filterArray(spec.days))
        makeArray(spec, o)
      when "monthly_day"
        # initialize basic properties
        o = gen(spec, RepeatingInterval.MonthlyDay)
        # setup specific propertities
        weeks = for x in spec.days when x isnt ""
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
