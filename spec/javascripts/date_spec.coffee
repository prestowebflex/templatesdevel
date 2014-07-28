describe "Date", ->
  it "has equal value and getTime", ->
    d = new Date(0)
    expect(d.valueOf()).toEqual 0
    expect(d.getTime()).toEqual 0
    expect(d.valueOf()).toEqual d.getTime()
    d1 = new Date(d.valueOf())
    expect(d1.getTime()).toEqual d.getTime()
    d1 = new Date(d.getTime())
    expect(d1.getTime()).toEqual d.valueOf()
  describe "Equal Dates", ->
    d1 = d = md = null
    beforeEach ->
      d = new Date()
      md = new MyDate(d)
      d1 = null
    it "getDateArray", ->
      a = md.getDateArray()
      console.log md
      d1 = new MyDate(a[0], a[1], a[2], a[3], a[4], a[5], a[6])
      #d1 = Object.create(Date::)
      #Date.apply(d1,md.getDateArray())
    it "getDateObject", ->
      d1 = new MyDate(md.getDateArray())  
    it "works with partial array also check setter functions", ->
      d1 = new MyDate(md.getDateArray()[0..2])
      d1 = d1.setHours(md.getDateArray()[3])
      d1 = d1.setMinutes(md.getDateArray()[4])
      d1 = d1.setSeconds(md.getDateArray()[5])
      d1 = d1.setMilliseconds(md.getDateArray()[6])
      
      #console.log(d1)
    afterEach ->
      expect(d1.getTime()).toEqual d.getTime()
      #expect(`d==d1`).toBe true
  xdescribe "As Days of Week", ->
    it "works out next Tuesday Given a saturday", ->
      d = Date()
      expect(d.dateOfWeek).toBe 1
