#= require time_interval
#= require repeating_interval
#= require repeating_interval_generator
@node = node = new Node
  data: 
    html_before: "
      <p>Text before pick a box</p>
      "
    html_after: "
      <p>Text after pick a box</p>
      "
    prizes:
      1:
        html: "Try Again :("
        odds: 50
        coupons: {}
      2:
        html: "You Win"
        odds: 50
        coupons:
          1:
            title: "My Coupon"
            html: "Free Something"
            type: "weekly"
            days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1

$ =>
  # initialize pick a box
  @boxes = boxes = new PickABox node.get("data"), node
  
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
                        <p>#{interval.getStart().toLocaleString()} - #{interval.getEnd().toLocaleString()}</p>
                     """
      $('.coupons').append """
            <div data-content-theme='a' data-role='collapsible' data-theme='a'>
              <h3>#{coupon.title}</h3>
              #{coupon.html}
              #{intervals}
              <a class='couponclaim ui-disabled' data-role='button' href='#'>Claim</a>
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
  
  # this is just to flip panel bits only.
  # trigger the update of grabbing a prize and initialize it.
  $(".panel .back").click ->
    refreshPanel()
    false
    #panel = $(@).parents(".panel")
    #console.log panel.parent().find(".panel")
    #.removeClass "hidden flipped"
  $(".panel").click ->
    $_  = $(@)
    unless $_.hasClass("flipped") or $_.hasClass("revealed")
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
      new Coupon("#{@id}-#{id}", coupon)
    console.log @coupons
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
    for nd in nodedatas
      data = nd.attributes 
      coupondata = pickabox.getCoupon data.couponid
      new @(data.couponid, _.extend(coupondata,data))
  constructor: (@id, @data = {}) ->
    # fixed information
    {@html, @title} = @data
    # generate the intervals generator from the data
    # this depends if we are using the resurected json form
    if @data.intervals
      @intervals = (new TimeInterval(interval) for interval in @data.intervals) 
    else
      @intervals = RepeatingIntervalGenerator.generate @data # if intervals not set???
  # first start of interval - used to sort
  earliestDate: ->
    # used to order coupons
    _.min @intervals, (o) -> o.getStart()
  latestDate: ->
    # used to remove expired coupons
    _.max @intervals, (o) -> o.getEnd()
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
    alert 'claim!'
  toJSON: ->
    # overload this to create the JSON representation of a coupon
    _datatype: "coupon"
    intervals: @intervals
    couponid: @id
    claimed: @claimed
