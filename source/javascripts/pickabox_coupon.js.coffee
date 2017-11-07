
# setup mocks for cordova native dialogs (if not present)

window.navigator = {} unless window.navigator?
window.navigator.notification = {} unless window.navigator.notification?

unless window.navigator.notification.confirm?
  window.navigator.notification.confirm = (message, callback, title, buttons) ->
      callback? if confirm("#{title}\n#{message}") then 1 else 2
      return
unless window.navigator.notification.alert?
  window.navigator.notification.alert = (message, callback, title, buttons) ->
      alert "#{title}\n#{message}"
      callback?()
      return
 
uuid = yourapp.getuuid()
access_token = localStorage.getItem('access_token')
setupHeaders = (xhr) ->
  xhr.setRequestHeader 'Authorization', "Bearer #{access_token}" if access_token?
  xhr.setRequestHeader 'X-Client-UUID', uuid
  for key, value of top.VERSION
    xhr.setRequestHeader "X-Client-#{key}", value
  xhr.setRequestHeader 'X-Requested-With', 'XMLHttpRequest'
  true


pickabox = (node, jQuery) ->
  
  # process html via collection
  html = (jquery, html) ->
    # load in html
    jquery.html html
    # proces each image
    jquery.find("img").not("[src]").each (i) ->
      img = $ @
      node.collection.getAsync "image", img.data("image"), (image) ->
        image.geturl (href) ->
          img.attr "src", href

  # quick mockup around jquery
  $ = (selector) ->
    jQuery.find selector
  # initialize pick a box
  boxes = new PickABox node.get("content"), node
  
  html $(".html_before"), boxes.html_before  
  html $(".html_after"), boxes.html_after  
  html $(".try_again"), boxes.html_tryagain  
  #prizes = boxes.getPrizes 16
  
  #refresh panel based upon the state of the boxes
  refreshPanel = (revealbox) ->
    pb = $(".pickabox").removeClass("available unavailable")
    if boxes.isValid()
      pb.addClass "available"
    else
      pb.addClass "unavailable"
    $(".panel").removeClass("flipped hidden revealed available").each ->
      p = $(@)
      box = p.data "box"
      # remove presentastional classes
      # determine if drawn
      if boxes.isRevealed(box) and revealbox != box
        p.addClass "revealed"
      else
        p.addClass "available"
  
  @coupons = []
  findCoupon = (id) ->
    _.find(@coupons, (c) -> c.id is id)
  refreshPanel()
    
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
    return false unless boxes.isValid()
    $_  = $(@)
    #return if $_.parent().find(".flipped").length
    #unless $_.hasClass("flipped") or $_.hasClass("revealed")
    prize = boxes.getPrize($_.data("box"))
    #console.log
    html $_.find(".back > .info"), prize.html
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

  # get the coupon tab click ready
  $("[data-role=navbar] a[data-panel=coupons]").click ->
    content = node.get('content')
    nodeindex = node.collection.get('nodeindex')
    pageLocation = nodeindex.get('nodes')[content.coupon_page]
    if !content.coupon_page
      navigator.notification.alert 'There is no coupons page defined, please notify the page owner', (->), "Error", "Return"
    else
      confirmCallback = (confirmResult) ->
        if confirmResult == 1
          window.jQuery.mobile.changePage pageLocation.name, {reloadPage: true}
          true
      window.navigator.notification.confirm 'Navigate to the coupons page?',confirmCallback , 'View coupons', ['Ok', 'Cancel']
    false


# pick a box pulls from a pool of prizes
class PickABox
  prize_pool: null
  html_before: ""
  html_after: ""
  html_tryagain: "Try Again"
  # number of items in the pool
  pool_size: null
  # size of the grid
  size: 16
  drawn_prizes: null # the prize state as drawn
  draws: 0
  drawn: 0
  constructor: (data = {}, @node) ->
    {@html_before,@html_after,@html_tryagain,@draws} = data
    @pool_size = Number(data.pool_size ? 100)
    @prize_pool = for id, prize of data.prizes
      # TODO don't include prizes which fall outsize the date spec
      new Prize(id, prize)
    # put THE dud prize into the prize pool now
    @prize_pool.push new Prize(0, {html: data.html_nowin, odds: (@pool_size - @_calculatePoolSize())})
    # predraw the prizes now
    @prizes = @getRandomPrizes()
    @drawn_prizes = [] # store the drawn prizes somewhere
    
    # make it reset at midnight every day by default
    interval = RepeatingIntervalGenerator.generate(_.extend {type: "everyday", hour:0, minute:0}, data, {length: 0, allday: 0, times: 1})[0]
    period = interval.prev().getStart() # get the start of the previous period
    @next_period = interval.getStart() # this is the time to start the next interval
    # filter this by date number of records is the box count
    @drawn = _.chain(@node.where(_datatype:"boxshow")).select((v) ->
        d = new Date(v.get("timedrawn"))
        d.valueOf() > period.valueOf()
       ).value().length
  # generate N number of prizes as an array
  getRandomPrizes: (number) ->
    number = @size unless number?
    @generateRandomPrize() for [1..number]
  
  # get a prize for a boxx
  getPrize: (number) ->
    if !@isRevealed(number) and @isValid() 
      @node.create(_datatype:"boxshow", timedrawn: new Date())
      @drawn++
      @prizes[number].generateCoupons(@node)
      @drawn_prizes[number] = @prizes[number]
  
  # is the prize revaled
  isRevealed: (boxNumber) ->
    @drawn_prizes[boxNumber]?
  
  # is the current pick a box valid to draw from
  isValid: ->
    @drawn < @draws   
  # genrate single prize
  generateRandomPrize: ->
    # draw a prize based upon the pool size and odds etc...
    number = Math.random() * @getPoolSize() # number between 
    # decrement number till it's -ve
    for prize in @prize_pool
      number -= prize.odds
      return prize if number < 0
  # prize pool size
  getPoolSize: -> @pool_size
  
  _calculatePoolSize: ->
    pool_size = 0
    for prize in @prize_pool
      pool_size += prize.odds
    pool_size
    
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
    @odds = Number(@odds)
    #@data.coupons = {} unless @data.coupons?
    #@coupon_ids = _.chain(@data.coupon_ids or []).map((id) -> Number(id)).compact().value()

  _getCouponData: ->
    _.compact(for id, coupon of @data.coupons
        if coupon.coupon_id?
          {id: Number(coupon.coupon_id), max_redeems: Number(coupon.coupon_count) or 1}
      )
  generateCoupons: (node) ->
    generateCouponsSuccess = (data, textStatus, jqXHR) =>
      # data includes:
      #  message to be displayed: success or fail
      window.navigator.notification.alert "Coupons created successfully", (->), "Prize awarded"

    generateCouponsError = (data, textStatus, jqXHR) =>
      window.navigator.notification.confirm "Error generating coupons, retry?", (buttonIndex) ->
        if buttonIndex==1
          # retry ajax
          doAjax()
        return
      , "Error", "Yes,Dismiss"

    doAjax = () =>
      # generate coupons via ajax
      $.ajax({ 
          url: node.collection.url() + "/coupons/create_many",
          data: JSON.stringify({client_time: new Date(), coupons: @_getCouponData()}),
          dataType: 'json',
          contentType: 'application/json',
          type: 'POST',
          beforeSend: setupHeaders,
          success: generateCouponsSuccess,
          error: generateCouponsError
      })
      return

    doAjax() if @data.coupons?

    # stub function finish this off
  getCoupon: (id) ->
    @data.coupons[id]
    
RepeatingIntervalGenerator = 
  generate: (spec) ->
    # initialize one of the time based classes
    gen = (spec={}, kls) ->
      o = new kls()
      unless spec.allday=="1"
        o.setMinutes(spec.length) if spec.length?
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
      when "everyday"
        o = gen(spec, RepeatingInterval.EveryDay)
        # has no options
        makeArray(spec, o)
      when "weekly"
        # initialize basic properties
        o = gen(spec, RepeatingInterval.Daily)
        # setup specific propertities
        o.setDays(filterArray(spec.week_days))
        makeArray(spec, o)
      when "monthly"
        # initialize basic properties
        o = gen(spec, RepeatingInterval.MonthlyDate)
        # setup specific propertities
        o.setDates(filterArray(spec.month_dates))
        makeArray(spec, o)
      when "monthly_day"
        # initialize basic properties
        o = gen(spec, RepeatingInterval.MonthlyDay)
        # setup specific propertities
        weeks = for x in spec.month_days when x isnt ""
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
      @[opt] = new Date(options[opt]) if options[opt]?
  setStart: (start) ->
    @start = new Date(start.valueOf?() ? start)
  setEnd: (end) ->
    @end = new Date(end.valueOf?() ? end)
  # make clones of the date objects
  getStart: -> new Date(@start.valueOf())
  getEnd: -> new Date(@end.valueOf())
  getLength: -> @getEnd().valueOf() - @getStart().valueOf()
  isWithinInterval: (date = new Date()) ->
    @getEnd().valueOf() > date.valueOf() >= @getStart().valueOf()
  isSameDay: -> @valuesSame "Date", "Month", "FullYear"
  # check if a bunch of values are the same
  valuesSame: (values...) ->
    for value in values
      return false unless @getStart()["get#{value}"]() == @getEnd()["get#{value}"]() 
    true
  equals: (interval) ->
    @getStart().valueOf?()==interval?.getStart().valueOf?() and @getEnd().valueOf?()==interval?.getEnd().valueOf?()  
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
      if @valuesSame "Hours", "Minutes"
        "#{@getStart().toDateString()} #{hour(end)}"
      else
        "#{@getStart().toDateString()} #{hour(start,end)}-#{hour(end)}"
    else
      "#{@getStart().toDateString()} #{hour(start)}-#{@getEnd().toDateString()} #{hour(end)}"
  toJSON: ->
    start: @getStart()
    end: @getEnd()

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
  _dateAdjust = (date, offsetMs) ->
    # compensate for crossing DST boundries
#    d = "#{date}, #{offsetMs/1000/60*60}"
    tz = date.getTimezoneOffset()
    newDate = new Date(date.getTime() + offsetMs)
    adjust = tz - newDate.getTimezoneOffset()
    if adjust != 0
      newDate.setTime newDate.getTime() - (1000*60*adjust) # adjust for DST
#      console.log "BEFORE:#{d}, AFTER:#{newDate}"
    newDate
  constructor: (@spec, @starttime) ->
    # work out the next interval based upon the spec
    # keep adding 1 day to starttime until the day matches one of the array values
    # then set the start time approiapetly
    # compare to starttime if greater than start time it's good
    # start the loop off
    start = new Date(@starttime.valueOf()) # use the end date
    # adjust date first
    start = _dateAdjust(start, -1000*24*60*60 * @constructor.scandays)
    # then reset time bits
    start = @spec._resetTime(start)
    # rewind 7 days and set the correct start time
#    console.log "START", start, @starttime
    # use greater than or equals here this is MILLISECONDS resolution here
    until (start.valueOf()+@spec.getLength()) > @starttime.valueOf() and @_validDate(start)
      start = _dateAdjust(start, 1000*24*60*60)
#      console.log "CHECK DATE", start
    @setStart start
    @setEnd _dateAdjust(start, @spec.getLength())
#    console.log "END: #{@getEnd()}"
  next: ->
    throw Error "unimplemented method" unless @spec.constructor.intervalClass
    # creep it forward 1 ms to move out of current range
    new @spec.constructor.intervalClass(@spec, new Date(@getEnd().valueOf()+1))

  # the supplied interval ENDS before the START of this interval
  prev: ->
    # keep going back 1 day at a time until the next() == this
    # that object is then the previous interval return it
    searchStart = @getStart()
    interval = @
    counter = 0
    #console.log "INTERVAL IS #{@}"
    # start of this interval is < than the end of the following interval
    #@getStart().valueOf?()==interval?.getStart().valueOf?() and @getEnd().valueOf?()==interval?.getEnd().valueOf?()

    until @equals n=interval.next()
      searchStart = _dateAdjust(searchStart, -1000*24*60*60)
      #searchStart.setUTCDate searchStart.getUTCDate() - 1
      interval = new @spec.constructor.intervalClass(@spec, searchStart.valueOf())
#      console.log "#{@}"
#      console.log "DATE: #{searchStart} INT: #{interval} NEXT:#{n} EQ: #{@equals n}"
      #console.log "NEXT:#{n.getStart().valueOf()-@getStart().valueOf()}-#{n.getEnd().valueOf()-@getEnd().valueOf()} THIS:#{interval.getStart().valueOf()}-#{interval.getEnd().valueOf()}"
      if ++counter > 120 # days
        throw Error "Infinite loop tried #{counter} times!"
    interval
      
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
    prev: -> @interval().prev()
    equals: (interval) -> @interval().equals(interval)
    getStart: -> @interval().getStart()
    getEnd: -> @interval().getEnd()
        
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
      #new Date(date.getYear(), date.getMonth(), date.getDate(), 1*@hour, 1*@minute, 1*@second, 1*@millisecond)
      #      date.setHours @hour
      #      date.setMinutes @minute
      #      date.setSeconds @second
      #      date.setMilliseconds @millisecond
      # get midnight on the day in question
      day = new Date(date.getFullYear(), date.getMonth(), date.getDate())
      tz = day.getTimezoneOffset()
      hour = day.getHours()
      if hour != 0
        if hour > 12
          day.setTime(day.getTime() + (1000*60*60*(24-hour)))
        else
          day.setTime(day.getTime() - (1000*60*60*hour))
      newDate = new Date(day.getTime() + 1000*60*60*@hour + 1000*60*@minute + 1000*@second + 1*@millisecond)
      adjust = tz - newDate.getTimezoneOffset()
      if adjust != 0
        newDate.setTime newDate.getTime() - (1000*60*adjust) # adjust for DST
      newDate
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
  class @EveryDay extends @Daily
    setDays: -> # null function  
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
      prev: ->
        throw Error "Not Implemented"
    @intervalClass: NumberOfDaysRepeatingInterval
      


@RepeatingIntervalGenerator = RepeatingIntervalGenerator
@RepeatingInterval = RepeatingInterval
@TimeInterval = TimeInterval
@pickabox = pickabox
@PickABox = PickABox
