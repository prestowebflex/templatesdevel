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
  prizes = boxes.getPrizes 16
  
  $(".panel").click ->
    console.log $(@).data "box"
    return
    if $(@).hasClass "flipped"
      # viewing backside of card
      # put back to front of card #mark as revealed
      $(@).parent().find(".panel").removeClass "hidden"
      $(@).removeClass "flipped"
    else
      # determine if the panel has been viewed before
      # How is this to be done
      $(@).removeClass "selectable"
      $(@).parent().find(".panel").not(@).addClass "hidden"
      $(@).addClass "flipped"
    false
  .on "touch", ->
    false

# pick a box pulls from a pool of prizes
class PickABox
  prize_pool: []
  html_before: ""
  html_after: ""
  # number of items in the pool
  pool_size: null
  # size of the grid
  size: 16
  
  constructor: (data = {}) ->
    {html_before: @html_before, html_after: @html_after} = data
    @prize_pool = for id, prize of data.prizes
      # TODO don't include prizes which fall outsize the date spec
      new Prize(id, prize)
  
  # generate N number of prizes as an array
  getPrizes: (number) ->
    number = @size unless number?
    @getPrize() for [1..number]
  
  # genrate single prize
  getPrize: ->
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
    throw Error "Not implenented"
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
      new Coupon(id, coupon)
  
# a coupon represents a coupon
class Coupon
  id: null # needs an identifier
  html: ""
  intervals: null
  constructor: (@id, data = {}) ->
    {html: @html} = data
    # generate the intervals generator from the data
    @intervals = RepeatingIntervalGenerator.generate data
    
