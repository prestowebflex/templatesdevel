$ ->
  $(".panel").click ->
    if $(@).hasClass "flipped"
      $(@).parent().find(".panel").removeClass "hidden"
      $(@).removeClass "flipped"
    else
      $(@).parent().find(".panel").not(@).addClass "hidden"
      $(@).addClass "flipped"
    false
  .touch ->
    false
