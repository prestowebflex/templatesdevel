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
  it "7-8pm", ->
    expect(int(t(19), t(20))).toMatch /7-8pm$/
  it "9am-5pm", ->
    expect(int(t(9), t(17))).toMatch /9am-5pm$/
  it "midnight-11:59pm", ->
    expect(int(t(0), t(23,59,59,999))).toMatch /midnight-11:59pm$/
  it "midday-11:59pm", ->
    expect(int(t(12), t(23,59,59,999))).toMatch /midday-11:59pm$/
  it "7:30am-midday", ->
    expect(int(t(7,30), t(12))).toMatch /7:30am-midday$/
  it "prints same day", ->
    expect(int(d(8,8,2014,9), d(8,8,2014,10))).toMatch /^Fri Aug 08 2014 9-10am$/
  it "prints different days", ->
    expect(int(d(7,8,2014,9), d(8,8,2014,10))).toMatch /^Thu Aug 07 2014 9am-Fri Aug 08 2014 10am$/
  