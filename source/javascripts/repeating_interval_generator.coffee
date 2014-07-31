# initialize one of the time based classes
gen = (spec, kls) ->
  gen = new kls()
  gen.setMinutes(spec.length) if spec.length
  gen.setStartTime(spec.hour, spec.minute) if spec.hour and spec.minute unless spec.allday
filterArray = (array) -> 
  Number(x) for x in array when x isnt ""
makeArray = (spec, generator) ->
  intervals = []
  for x in [1..Number(spec.times)]
    intervals.push generator.next()
  intervals
@RepeatingIntervalGenerator =
  generate: (spec) ->
    switch spec.type
      when "weekly"
        # initialize basic properties
        gen(spec, RepeatingInterval.Daily)
        # setup specific propertities
        gen.setDays(filterArray(spec.days))
        makeArray(spec, gen)
      else
        throw Error "Unknown type #{spec.type}!"
