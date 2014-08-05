#= require time_interval
#= require repeating_interval
#= require repeating_interval_generator
$ =>
  # initialize pick a box
  @boxes = boxes = new PickABox
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
            html: "Free Something"
            type: "weekly"
            days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
  
  $(".html_before").html boxes.html_before
  $(".html_after").html boxes.html_after
  #prizes = boxes.getPrizes 16
  
  #refresh panel based upon the state of the boxes
  refreshPanel = ->
    $(".panel").removeClass("flipped hidden revealed available").each ->
      p = $(@)
      box = p.data "box"
      # remove presentastional classes
      # determine if drawn
      if boxes.isRevealed(box)
        p.addClass "revealed"
      else
        p.addClass "available"
        
  refreshCoupons = ->
    
    
  refreshPanel()
  # this is just to flip panel bits only.
  # trigger the update of grabbing a prize and initialize it.
  $(".panel .buttonbar a").click ->
    refreshPanel()
    false
    #panel = $(@).parents(".panel")
    #console.log panel.parent().find(".panel")
    #.removeClass "hidden flipped"
  $(".panel").click ->
    unless $(@).hasClass "flipped"
      prize = boxes.getPrize($(@).data("box"))
      #console.log 
      $(@).find(".back > .info").html prize.html
      #console.log prize
       # setup the dada
      refreshPanel()
      # setup the visuals
      $(@).addClass "flipped"
      $(@).parent().find(".panel").not(@).addClass "hidden"
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
  
  constructor: (data = {}) ->
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
    @prizes[number].generateCoupons()
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
    throw Error "Not implemented"
# a prize includes 1 or more coupons
class Prize
  coupons: []
  id: null # needs an identifier
  odds: 0 # never drawn out
  validTo: new Date(2038,1,1) # leave this out for now
  validFrom: new Date(0) # leave this out for now
  html: ""
  constructor: (@id, data = {}) ->
    {html: @html, odds: @odds} = data
    @coupons = for id, coupon of data.coupons
      new Coupon("#{@id}-#{id}", coupon)
  generateCoupons: ->
    # stub function finish this off
  
# a coupon represents a coupon
# maybe they are initialized from the user data instead
class Coupon
  id: null # needs an identifier
  html: ""
  intervals: null
  constructor: (@id, @data = {}) ->
    {html: @html} = @data
    # generate the intervals generator from the data
    #@intervals = RepeatingIntervalGenerator.generate data
    
