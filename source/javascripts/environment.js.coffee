node = new Node
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
            days: [0,1,2,3,4,5,6]
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

$ ->
  pickabox node, $("div[data-role=content]")
