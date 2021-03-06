describe "Time Interval", ->
  ###
    7-8pm should come out like that
    7am-11pm should come out like that
    7:35-11:46pm should look like that
  ###
  setTime = (date,h,m=0,s=0,ms=0) ->
    date.setHours h
    date.setMinutes m
    date.setSeconds s
    date.setMilliseconds ms
    date
  # setup a time only - only useful to regexp off times
  t = (h,m=0,s=0,ms=0) ->
    setTime new Date(), h,m,s,ms
  d = (d,month,y,h=0,m=0,s=0,ms=0) ->
    new Date(y,month-1,d,h,m,s,ms)
  int = (s,e) ->
    new TimeInterval(start:s,end:e).toString()
  it "equals an identical interval", ->
    start = new Date(1234)
    end = new Date(4567)
    i1 = new TimeInterval(start:start, end:end )
    i2 = new TimeInterval(start:start, end:end )
    expect(i1.equals(i2)).toEqual(true)
    expect(i2.equals(i1)).toEqual(true)
  it "not equals an non identical interval end", ->
    start = new Date(1234)
    end = new Date(4567)
    i1 = new TimeInterval(start:start, end:end )
    i2 = new TimeInterval(start:start, end:4568 )
    expect(i1.equals(i2)).toEqual(false)
    expect(i2.equals(i1)).toEqual(false)
  it "not equals an non identical interval start", ->
    start = new Date(1234)
    end = new Date(4567)
    i1 = new TimeInterval(start:start, end:end )
    i2 = new TimeInterval(start:1235, end:end )
    expect(i1.equals(i2)).toEqual(false)
    expect(i2.equals(i1)).toEqual(false)
  it "not equals an non identical interval both", ->
    start = new Date(1234)
    end = new Date(4567)
    i1 = new TimeInterval(start:start, end:end )
    i2 = new TimeInterval(start:1235, end:4568 )
    expect(i1.equals(i2)).toEqual(false)
    expect(i2.equals(i1)).toEqual(false)
  it "7pm", ->
    expect(int(t(19), t(19))).toMatch /7pm$/
  it "7-8pm", ->
    expect(int(t(19), t(20))).toMatch /7-8pm$/
  it "9am-5pm", ->
    expect(int(t(9), t(17))).toMatch /9am-5pm$/
  it "midnight-11:59pm", ->
    expect(int(t(0), t(23,59,59,999))).toMatch /midnight-11:59pm$/
  it "11:59pm", ->
    expect(int(t(23,59,59,999),t(23,59,59,999))).toMatch /11:59pm$/
  it "midday-11:59pm", ->
    expect(int(t(12), t(23,59,59,999))).toMatch /midday-11:59pm$/
  it "7:30am-midday", ->
    expect(int(t(7,30), t(12))).toMatch /7:30am-midday$/
  it "prints same start and end time", ->
    expect(int(d(8,8,2014,9), d(8,8,2014,9))).toMatch /^Fri Aug 08 2014 9am$/
  it "prints same day", ->
    expect(int(d(8,8,2014,9), d(8,8,2014,10))).toMatch /^Fri Aug 08 2014 9-10am$/
  it "prints different days", ->
    expect(int(d(7,8,2014,9), d(8,8,2014,10))).toMatch /^Thu Aug 07 2014 9am-Fri Aug 08 2014 10am$/
  