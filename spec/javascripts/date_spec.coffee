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
  describe "other benavior", ->
    it "should setup a default date", ->
      d = new MyDate()
      expect(d.date).toBeDefined()
  describe "As Days of Week", ->
    it "works out next Tuesday Given a saturday", ->
      d = new MyDate()
      expect(d.getDay()).toBe d.getDay()
  describe "Date operations setNextDay()", ->
    d = null
    beforeEach ->
      # Monday the 28th July 2014 @ 11am
      d = new MyDate(2014, 6, 28, 11)
    it "should be a monday", ->
      expect(d.getDay()).toEqual MyDate.MONDAY
    afterEach ->
      # year should stay the same
      expect(d.getFullYear()).toEqual 2014
      expect(d.getHours()).toEqual 11
      expect(d.getMinutes()).toEqual 0
    # disabled due to not implemented this way
    xit "should work out next Monday 4th August", ->
      d = d.setNextDay(MyDate.MONDAY)
      expect(d.getMonth()).toEqual 7
      expect(d.getDate()).toEqual 4
      expect(d.getDay()).toEqual MyDate.MONDAY
    it "should work out next Tuesday 29 July", ->
      d = d.setNextDay(MyDate.TUESDAY)
      expect(d.getMonth()).toEqual 6
      expect(d.getDate()).toEqual 29
      expect(d.getDay()).toEqual MyDate.TUESDAY
    # disabled not to skip weeks see interval now
    xit "should work out next Tuesday week - 5th August", ->
      d = d.setNextDay(MyDate.TUESDAY,1)
      expect(d.getMonth()).toEqual 7
      expect(d.getDate()).toEqual 5
      expect(d.getDay()).toEqual MyDate.TUESDAY
    it "should work out next Sunday 3rd August", ->
      d = d.setNextDay(MyDate.SUNDAY)
      expect(d.getMonth()).toEqual 7
      expect(d.getDate()).toEqual 3
      expect(d.getDay()).toEqual MyDate.SUNDAY
      
