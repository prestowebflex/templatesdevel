# stub phonegap functions - especially the confirm function for coupons

# mock for barcodescanner plugin for phonegap
# also for pick a box
unless cordova?
  window.navigator ?= {}
  window.navigator.notification ?= {}
  
  window.navigator.notification = 
    mock: true
    confirm: (message, callback, title, buttons) ->
      callback? if confirm("#{title}\n#{message}") then 1 else 2
      return
    alert: (message, callback, title, buttons) ->
      alert "#{title}\n#{message}"
      callback?()
      return
    prompt: (message, callback, title, buttons) ->
      results = 
        input1: prompt("#{title}\n#{message}")
        
      results["buttonIndex"] = if results.input1 != null then 1 else 2
      console.log results
      callback? results
      return