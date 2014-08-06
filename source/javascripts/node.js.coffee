# abstract class
class Obj
  constructor: (@attributes = {}) ->
    @set "updated_at", new Date()
    @set "created_at", new Date()
  
  # make values as a json value not native objects
  # this stuffs around with dates
  set: (key, value) ->
    @attributes[key] = JSON.parse(JSON.stringify(value))
  get: (key) ->
    @attributes[key]
  # stub save method
  save: ->
    true
  # dud function keep things happy
  destroy: ->
    true
    

# node has many node data's accessable via create and getNodeData
class @Node extends Obj
  constructor: ->
    @nodedata = []
    super
  getNodeData: ->
    # FAKE STUB
    @nodedata

  create: (data={}) ->
    @nodedata.push new NodeData data: data
  where: (conditions={}) ->
    _.filter(@getNodeData(), (obj) ->
        for key, value of conditions
          if obj.get(key) != value
            return false
        true
      )
    

class NodeData extends Obj
