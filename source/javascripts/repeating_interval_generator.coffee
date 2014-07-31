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
      intervals = intervals[1...]
  else
    # chop the end off
    intervals = intervals[...-1]
  # else chop the last one off 
  #  intervals.push generator.next()
  intervals
@RepeatingIntervalGenerator =
  generate: (spec) ->
    switch spec.type
      when "weekly"
        # initialize basic properties
        o = gen(spec, RepeatingInterval.Daily)
        # setup specific propertities
        o.setDays(filterArray(spec.days))
        makeArray(spec, o)
      else
        throw Error "Unknown type #{spec.type}!"
