describe "PickABox", ->
  beforeEach ->
    @node = new Node
      content: 
        html_before: "
          <p>AA Text before pick a box</p>
          "
        html_after: "
          <p>AA Text after pick a box</p>
          "
        html_tryagain: "
          <p>AA Try again tomorrow</p>
        "
        draws: "4"
        pool_size: "2"
        html_tryagain: "AA Try Again :( <img />"
        type: "daily" # just midnight every day 0 length only using start of interval
        prizes:
          2:
            html: "AA You Win"
            odds: "1"
            coupons:
              1:
                title: "AA y Coupon"
                html: "Free Something"
                type: "weekly"
                week_days: [0,1,2,3,4,5,6]
                hour: 17
                minute: 0
                length: 180
                times: 5
                leeway_before: 60
                generate_extra: 1
              2:
                title: "AA My Coupon #2"
                html: "Free Something always"
                type: "duration_days"
                days: 5
    @box = new PickABox(@node.get("content"), @node)
  afterEach ->
    jasmine.clock().uninstall()
  it "random tests", ->
    # can generate 0 but not 1
    p1 = 0
    p2 = 0
    #array = 
    for [1..20000]
      if Math.random()*100 < 50
        p1++
      else
        p2++
    alert "P1:#{p1} P2:#{p2} P1-P2:#{p1-p2} %#{(p1-p2) / (p1+p2)*100}"
  it "underscore random with low number", ->
    array = for [1..1000]
      _.random 2
    expect(array).toContain 0
    expect(array).toContain 1
    expect(array).toContain 2
  it "has correct size prize pool", ->
    expect(@box.prize_pool.length).toEqual 2
  it "has correct count", ->
    expect(@box.getPoolSize()).toEqual 2
  it "always draws random prize", ->
    for [1..1000]
      expect(@box.generateRandomPrize()).toBeDefined()
  it "has 16 defined prizes", ->
    for prize in @box.prizes
      expect(prize).toBeDefined()
  it "can only draw 4 times across page reloads", ->
    expect(@box.isValid()).toEqual true
    @box.getPrize(1)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(2)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(3)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(4)
    expect(@box.isValid()).toEqual false

  it "can only draw 4 times across page reloads and new dates", ->
    @clock = jasmine.clock().install()
    @clock.mockDate(new Date(2014,0,2,16,30))
    # Day 1
    expect(@box.isValid()).toEqual true
    @box.getPrize(1)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(2)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(3)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(4)
    expect(@box.isValid()).toEqual false

    @clock.mockDate(new Date(2014,0,3,16,30))
    # Day 2
    @box = new PickABox(@node.get("content"), @node)
    expect(@box.isValid()).toEqual true
    @box.getPrize(1)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(2)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(3)
    expect(@box.isValid()).toEqual true

    @box = new PickABox(@node.get("content"), @node)
    @box.getPrize(4)
    expect(@box.isValid()).toEqual false
    
  it "can only draw 4 times", ->
    expect(@box.isValid()).toEqual true
    @box.getPrize(1)
    expect(@box.isValid()).toEqual true
    @box.getPrize(2)
    expect(@box.isValid()).toEqual true
    @box.getPrize(3)
    expect(@box.isValid()).toEqual true
    @box.getPrize(4)
    expect(@box.isValid()).toEqual false
    
