# abstract class
class Obj
  constructor: (attributes = {}) ->
    @attributes = JSON.parse(JSON.stringify(attributes))
    @log("constructor", @attributes)
    @set
      updated_at: new Date()
      created_at: new Date()
  
  # make values as a json value not native objects
  # this stuffs around with dates
  set: (obj, value) ->
    @log("set", obj, value)
    unless _.isObject(obj)
      o = {}
      o[obj] = value
      obj = o
    for key, value of obj
      @attributes[key] = JSON.parse(JSON.stringify(value))
  get: (key) ->
    value = @attributes[key]
    @log("get", key, value)
    value
  # stub save method
  save: ->
    true
  # dud function keep things happy
  destroy: ->
    true
  log: (method, values...) ->
    values = (JSON.stringify value for value in values)
    console.log "#{@constructor.name}##{method}", values...

# node has many node data's accessable via create and getNodeData
class @Node extends Obj
  constructor: ->
    @nodedata = []
    super
  getNodeData: ->
    # FAKE STUB
    @nodedata
  getRawId: -> 
    3
  collection:
    # only mock up for images
    getAsync: (obj, id, callback) ->
      callback?(
        geturl: (callback) -> callback? "http://placehold.it/350x150"
        )
  create: (data={}) ->
    @nodedata.push new NodeData data
  where: (conditions={}) ->
    result = _.filter(@getNodeData(), (obj) ->
        for key, value of conditions
          if obj.get(key) != value
            return false
        true
      )
    @log "where", conditions, result
    result
    

class NodeData extends Obj
