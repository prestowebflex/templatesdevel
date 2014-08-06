# stub phonegap functions - especially the confirm function for coupons

# mock for barcodescanner plugin for phonegap
unless cordova?
  window.navigator ?= {}
  window.navigator.notification ?= {}
  
  window.navigator.notification = 
    mock: true
    confirm: (message, callback, title, buttons) ->
      callback? if confirm(message) then 1 else 2
    alert: (message, callback, title, buttons) ->
      alert message
      callback?()
