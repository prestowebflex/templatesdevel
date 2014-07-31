###
  A time interval
  Declared as a length and start forumula
  
###
class @TimeInterval
  # has start / end
  # has start / duration
  setStart: (@start) ->
  setEnd: (@end) ->
  getStart: -> @start
  getEnd: -> @end
  getLength: -> @getEnd().valueOf() - @getStart().valueOf()
  isWithinInterval: (date) ->
    @getEnd().valueOf() > date.valueOf() >= @getStart().valueOf()
