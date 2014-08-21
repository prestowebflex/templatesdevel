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
        prizes:
          1:
            html: "AA Try Again :("
            odds: "1"
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