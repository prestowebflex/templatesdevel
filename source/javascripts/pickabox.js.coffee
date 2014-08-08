pickabox = (node, jQuery) ->
  # quick mockup around jquery
  $ = (selector) ->
    jQuery.find selector
  # initialize pick a box
  boxes = new PickABox node.get("content"), node
  
  $(".html_before").html boxes.html_before
  $(".html_after").html boxes.html_after
  #prizes = boxes.getPrizes 16
  
  #refresh panel based upon the state of the boxes
  refreshPanel = (revealbox) ->
    $(".panel").removeClass("flipped hidden revealed available").each ->
      p = $(@)
      box = p.data "box"
      # remove presentastional classes
      # determine if drawn
      if boxes.isRevealed(box) and revealbox != box
        p.addClass "revealed"
      else
        p.addClass "available"
    refreshCoupons() 
  
  @coupons = []
  findCoupon = (id) ->
    _.find(@coupons, (c) -> c.id is id)
  refreshCoupons = ->
    # this is the same as the panel, create node data's to represent the coupons
    @coupons = Coupon.generate node.where(_datatype:"coupon", claimed:null), boxes
    # TODO coupons needs to be sorted and filtered
    $('.couponcount').text @coupons.length
    $('.coupons').html ""
    for coupon in @coupons
      # TODO need to sort the intervals
      intervals = "<p>Valid from</p>"
      for interval in coupon.intervals
        intervals += """
                        <p>#{interval}</p>
                     """
      $('.coupons').append """
            <div data-couponid='#{coupon.id}' data-content-theme='a' data-role='collapsible' data-theme='a'>
              <h3>#{coupon.title} <span class="couponexpiry">#{coupon.latestDate().toDateString()}</span></h3>
              #{coupon.html}
              #{intervals}
              <a class='couponclaim#{if coupon.isClaimable() then "" else " ui-disabled"}' data-role='button' href='#'>Claim</a>
            </div>
                           """
    $('.coupons').trigger "create"
  refreshPanel()
  refreshCoupons()
  
  # deal with the link for pick a box and coupons
  # really only has to update coupon counts and change the box class
  $("[data-role=navbar] a").click ->
    $(".panels > div").hide()
    $(".panels > .#{$(@).data("panel")}").show()
  
  # coupon claim!
  $(".coupons").on "click", ".couponclaim:not(.ui-disabled)", {}, ->
    couponid =  $(@).parents("[data-couponid]").data "couponid"
    coupon = findCoupon couponid
    navigator.notification.confirm "Would you like to redeem the coupon now?", (buttonIndex) ->
      if buttonIndex==1
        coupon.claim()
        refreshCoupons()
    , "Redeem #{coupon.title}", "Yes,Dismiss"
    #console.log coupon
    #alert "claim! #{couponid}"
    false
  # this is just to flip panel bits only.
  # trigger the update of grabbing a prize and initialize it.
  $(".pickabox").on "click", ".flipped", {}, ->
    refreshPanel()
    false
    #panel = $(@).parents(".panel")
    #console.log panel.parent().find(".panel")
    #.removeClass "hidden flipped"

  # any front available facing box can be clicked
  # while nothing is flipped
  .on "click", ":not(:has(.flipped)) .available", {}, ->
    $_  = $(@)
    #return if $_.parent().find(".flipped").length
    #unless $_.hasClass("flipped") or $_.hasClass("revealed")
    prize = boxes.getPrize($_.data("box"))
    #console.log 
    $_.find(".back > .info").html prize.html
    #console.log prize
     # setup the dada
    refreshPanel($(@).data("box"))
    # setup the visuals
    $_.addClass "flipped"
    $_.parent().find(".panel").not(@).addClass "hidden"
    # viewing backside of card
    # # put back to front of card #mark as revealed
    # $(@).parent().find(".panel").removeClass "hidden"
    # $(@).removeClass "flipped"
  # else
    # # determine if the panel has been viewed before
    # # How is this to be done
    # $(@).removeClass "selectable"
    # $(@).parent().find(".panel").not(@).addClass "hidden"
    # $(@).addClass "flipped"
    false
  .on "touch", ->
    false
    




# pick a box pulls from a pool of prizes
class PickABox
  prize_pool: null
  html_before: ""
  html_after: ""
  # number of items in the pool
  pool_size: null
  # size of the grid
  size: 16
  drawn_prizes: null # the prize state as drawn
  
  constructor: (data = {}, @node) ->
    {html_before: @html_before, html_after: @html_after} = data
    @prize_pool = for id, prize of data.prizes
      # TODO don't include prizes which fall outsize the date spec
      new Prize(id, prize)
    # predraw the prizes now
    @prizes = @getRandomPrizes()
    @drawn_prizes = [] # store the drawn prizes somewhere
  # generate N number of prizes as an array
  getRandomPrizes: (number) ->
    number = @size unless number?
    @generateRandomPrize() for [1..number]
  
  # get a prize for a boxx
  getPrize: (number) ->
    @prizes[number].generateCoupons(@node)
    @drawn_prizes[number] = @prizes[number]
  
  # is the prize revaled
  isRevealed: (boxNumber) ->
    @drawn_prizes[boxNumber]?
  
  # genrate single prize
  generateRandomPrize: ->
    # draw a prize based upon the pool size and odds etc...
    number = _.random @getPoolSize() # eg 0-99 total odds
    # decrement number till it's -ve
    for prize in @prize_pool
      number -= prize.odds
      return prize if number < 0
  # prize pool size
  getPoolSize: ->
    if @pool_size==null
      @pool_size = 0
      for prize in @prize_pool
        @pool_size += prize.odds
    @pool_size
  getCoupon: (id) ->
    # get the id of a specific coupon
    # id is split into 2 parts
    [prizeId, couponId] = id.split("-")
    prize = _.find(@prize_pool, (o) -> o.id == prizeId)
    prize?.getCoupon couponId
# a prize includes 1 or more coupons
class Prize
  coupons: null
  id: null # needs an identifier
  odds: 0 # never drawn out
  validTo: new Date(2038,1,1) # leave this out for now
  validFrom: new Date(0) # leave this out for now
  html: ""
  constructor: (@id, @data = {}) ->
    {@html, @odds} = @data
  generateCoupons: (node) ->
    # call create off node to make up the necessary data
    @coupons = for id, coupon of @data.coupons
      new Coupon("#{@id}-#{id}-#{new Date().valueOf()}", coupon)
    node.create(coupon.toJSON()) for coupon in @coupons
    @coupons
    # stub function finish this off
  getCoupon: (id) ->
    @data.coupons[id]
# a coupon represents a coupon
# maybe they are initialized from the user data instead
# tie each coupon to it's own node data instance as well.
# saves updating when calling methods

# if initialized with node data the intervals are set etc...
# if initialised from prize then intervals set themselves
class Coupon
  id: null # needs an identifier
  html: "" # no html
  # intervals is an array of intervals
  intervals: null
  claimed: null
  # generate the coupons given the JSON data
  @generate: (nodedatas, pickabox) ->
    _.chain(
        for nd in nodedatas
          data = nd.attributes 
          coupondata = pickabox.getCoupon data.couponid
          # extend off an empty object as we don't want to copy intervals onto coupon data
          new @(data.couponid, _.extend({},coupondata,data), nd)
      )
      .reject (o) -> o.isExpired()
      .sortBy (o) -> o.created
      .reverse()
      .value()
  constructor: (@id, @data = {}, @obj = null) ->
    # fixed information
    {@html, @title} = @data
    # set claimed date if it's set
    @claimed = new Date(@data.claimed) if @data.claimed?
    @created = if @data.created?
        new Date(@data.created)
      else
        new Date()
    # generate the intervals generator from the data
    # this depends if we are using the resurected json form
    if @data.intervals
      @intervals = (new TimeInterval(interval) for interval in @data.intervals) 
    else
      @intervals = RepeatingIntervalGenerator.generate @data # if intervals not set???
  # first start of interval - used to sort
  earliestDate: ->
    # used to order coupons
    _.min(_.map @intervals, (o) -> o.getStart())
  latestDate: ->
    # used to remove expired coupons
    _.max(_.map @intervals, (o) -> o.getEnd())
  # coupon has expired
  isExpired: ->
    @latestDate().valueOf() < new Date().valueOf()
  # coupon has been claimed
  isClaimed: ->
    @claimed?
  # coupon is valid for display purposes
  isValid: ->
    !@isClaimed() and !@isExpired()
  # coupon is currently claimable
  isClaimable: ->
    _.some @intervals, (o) -> o.isWithinInterval()
  claim: ->
    unless @isClaimed()
      # set claimed to current date
      @claimed = new Date()
      #confirm this is correct
      @obj.set @toJSON()
      @obj.save
  toJSON: ->
    # overload this to create the JSON representation of a coupon
    _datatype: "coupon"
    intervals: @intervals
    couponid: @id
    claimed: @claimed
    created: @created


    
RepeatingIntervalGenerator = 
  generate: (spec) ->
    # initialize one of the time based classes
    gen = (spec={}, kls) ->
      o = new kls()
      unless spec.allday=="1"
        o.setMinutes(spec.length) if spec.length
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
      @[opt] = new Date(options[opt].valueOf?() || options[opt]) if options[opt]?
  setStart: (@start) ->
  setEnd: (@end) ->
  getStart: -> @start
  getEnd: -> @end
  getLength: -> @getEnd().valueOf() - @getStart().valueOf()
  isWithinInterval: (date = new Date()) ->
    @getEnd().valueOf() > date.valueOf() >= @getStart().valueOf()
  isSameDay: -> @valuesSame "Date", "Month", "FullYear"
  # check if a bunch of values are the same
  valuesSame: (values...) ->
    for value in values
      return false unless @getStart()["get#{value}"]() == @getEnd()["get#{value}"]() 
    true
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
      "#{@getStart().toDateString()} #{hour(start,end)}-#{hour(end)}"
    else
      "#{@getStart().toDateString()} #{hour(start)}-#{@getEnd().toDateString()} #{hour(end)}"
  toJSON: ->
    start: @start
    end: @end

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
    throw Error "unimplemented method" unless @spec.constructor.intervalClass
    # creep it forward 1 ms to move out of current range
    new @spec.constructor.intervalClass(@spec, new Date(@getEnd().valueOf()+1))
  
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

    @intervalClass: DailyRepeatingInterval
    
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
      
    @intervalClass: NumberOfDaysRepeatingInterval
      


@RepeatingIntervalGenerator = RepeatingIntervalGenerator
@RepeatingInterval = RepeatingInterval
@TimeInterval = TimeInterval
@pickabox = pickabox

