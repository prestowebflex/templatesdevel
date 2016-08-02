node = new Node
  updated_at: "3"
  content:
    html_before: """
      <p>Match 3 cards to win</p>
      <img data-src="" />
      """
    html_after: "
      <p>Text after tileflip</p>
      "
    html_gameover: "
      <p>Try again tomorrow</p>
    "
    flips: "16"
    max_daily_draws: "1"
    # use thse to rework out the pool size and try again etc...
    pool_size: "2"
    html_nowin: "<img src='images/tileflip/dud.png' />"
    card_back_html: "<img data-src='images/tileflip/back.jpg' data-image='123' />"
    card_back_color: "#111"
    type: "everyday" # just midnight every day 0 length only using start of interval
    hour: 0
    minute: 0
    box_image_aspect: 0.7142857143 #180/252
    prizes:
      2:
        html: "<img src='images/tileflip/prize1.png' />"
        odds: "0.3"
        number_to_collect: "3"
        coupons:
          1:
            title: "Free drink coupon"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize1.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
          2:
            title: "Free drink coupon 2"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize1.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
      3:
        html: "<img src='images/tileflip/prize2.png' />"
        odds: "0.3"
        number_to_collect: "3"
        coupons:
          1:
            title: "Blue drink coupon"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize2.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
          2:
            title: "Free drink coupon 2"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize1.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
      4:
        html: "<img src='images/tileflip/prize3.png' />"
        odds: "0.33"
        number_to_collect: "3"
        coupons:
          1:
            title: "Orange drink coupon"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize3.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
          2:
            title: "Free drink coupon 2"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize1.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
      5:
        html: "<img src='images/tileflip/prize4.png' />"
        odds: "0.33"
        number_to_collect: "3"
        coupons:
          1:
            title: "Orange drink coupon"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize3.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
          2:
            title: "Free drink coupon 2"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize1.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
      6:
        html: "<img src='images/tileflip/prize5.png' />"
        odds: "0.33"
        number_to_collect: "3"
        coupons:
          1:
            title: "Orange drink coupon"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize3.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
          2:
            title: "Free drink coupon 2"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize1.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
      7:
        html: "<img src='images/tileflip/prize6.png' />"
        odds: "0.33"
        number_to_collect: "3"
        coupons:
          1:
            title: "Orange drink coupon"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize3.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1
          2:
            title: "Free drink coupon 2"
            html: "You won a free drink by matching 3 cards <img src='images/tileflip/prize1.jpg' />"
            type: "weekly"
            week_days: [0,1,2,3,4,5,6]
            hour: 17
            minute: 0
            length: 180
            times: 5
            leeway_before: 60
            generate_extra: 1

$ ->
  # create some node data before starting
  node.create(_datatype:"boxshow", timedrawn: 'abc') for num in [1..2]
  # console.log node.nodedata
  # console.log node.getNodeData()
  # console.log node.where _datatype:"boxshow"
  # console.log _.chain(node.where(_datatype:"boxshow")).select((v) ->
  #     d = new Date(v.get("timedrawn"))
  #     console.log "Comparing #{d}"
  #     true
  #    ).value().length

  tileflip node, $("div[data-role=content]")
