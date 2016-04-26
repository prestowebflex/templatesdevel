tapHoldDebugPatch = ->
  unless window._tapholdpatchapplied
    window._tapholdpatchapplied = true
    # remove old patch
    window.$(window.document).unbind 'taphold'
    showDebugMessage = ->
      debug = []
      debug.push "#{key}: #{value}" for key, value of window.VERSION
      # change this line to use phonegap method
      navigator.notification.alert debug.join("\n"), null , "Version information", "OK"
      return
    timeout = null
    target = null
    window.$(window.document).bind 'taphold', (e) ->
      # e.target should be equal
      unless timeout?
        target = e.target
        timeout = setTimeout ->
            timeout = null
            target = null
            return
          , 3000
      else
        console.log "2"
        # clear timeout
        clearTimeout timeout
        # only show debug message if the same element touched twice
        if e.target == target
          showDebugMessage()
        timeout = null
        target = null
      return
  return
tapHoldDebugPatch()
