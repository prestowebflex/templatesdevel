# abstract class
class Obj
  constructor: (@attributes = {}) ->
    @set "updated_at", new Date()
    @set "created_at", new Date()
  
  set: (key, value) ->
    @attributes[key] = value
  get: (key) ->
    @attributes[key]
  destroy: ->
    # dud function keep things happy
    

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
