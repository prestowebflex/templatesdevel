node = new Node
  content: 
    html_before: "
      <p>Text before pick a box</p>
      "
    html_after: "
      <p>Text after pick a box</p>
      "
    html_tryagain: "
      <p>Try again tomorrow</p>
    "
    draws: 1
    prizes:
      1:
        html: "Try Again :("
        odds: 50
        coupons: {}
      2:
        html: "You Win"
        odds: 500
        coupons:
          1:
            title: "My Coupon"
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
            title: "My Coupon #2"
            html: "Free Something always"
            type: "duration_days"
            days: 5

$ ->
  pickabox node, $("div[data-role=content]")
