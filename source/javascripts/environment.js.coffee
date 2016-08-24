node = new Node
  content: 
    html_before: """
      <p>AA Text before pick a box</p>
      <img data-src="" />
      """
    html_after: "
      <p>AA Text after pick a box</p>
      "
    html_tryagain: "
      <p>AA Try again tomorrow</p>
    "
    draws: "4"
    # use these to rework out the pool size and try again etc...
    pool_size: "2"
    html_nowin: "AA Try Again :( <img />"
    type: "everyday" # just midnight every day 0 length only using start of interval
    hour: 0
    minute: 0
    prizes:
      2:
        html: "AA You Win <img />"
        odds: "1"
        coupons:
          1:
            title: "AA y Coupon"
            html: "Free Something <img />"
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
            html: "Free Something always <img />"
            type: "duration_days"
            days: 5
            claim_code: "demo"
            available_location: "1"
            available_location_radius: "21.30494666472023"
            available_location_latitude: "-32.83611403622155"
            available_location_longitude: "151.34505584836006"

$ ->
  pickabox node, $("div[data-role=content]")
