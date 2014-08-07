###
  A time interval
  Declared as a length and start forumula
  
###
class @TimeInterval
  # has start / end
  # has start / duration
  constructor: (options={}) ->
    for opt in ["start", "end"]
      @[opt] = new Date(options[opt].valueOf?() || options[opt]) if options[opt]?
  setStart: (@start) ->
  setEnd: (@end) ->
  getStart: -> @start
  getEnd: -> @end
  getLength: -> @getEnd().valueOf() - @getStart().valueOf()
  isWithinInterval: (date = new Date()) ->
    @getEnd().valueOf() > date.valueOf() >= @getStart().valueOf()
  toString: ->
    # TODO extend this to pretty print times
    # same say for example
    # Mon 2nd August 5-7pm
    # Mon 2nd August 5:30am-7pm
    # Mon 2nd August 12am-11:59:59pm
    # if different days then full print string
    "TimeInterval(#{@getStart()}-#{@getEnd()})"
  toJSON: ->
    start: @start
    end: @end
