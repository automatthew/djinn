Digraph = require("./digraph")
Graphviz = require("./graphviz")

class NaiveDigraph extends Digraph

  constructor: () ->
    super()
    @vertex_id_counter = 0
    @arc_id_counter = 0

  dump: (callback) ->
    data = super(callback)
    data.vertex_id_counter = this.vertex_id_counter
    data.arc_id_counter = this.arc_id_counter
    data

  load: (dump, transition_callback, states_callback) ->
    super(dump, transition_callback, states_callback)
    @vertex_id_counter = dump.vertex_id_counter
    @arc_id_counter = dump.arc_id_counter
    @

  next_vertex_id: ->
    @vertex_id_counter++

  next_arc_id: ->
    @arc_id_counter++

  create_vertex: (id=null) ->
    id ||= @next_vertex_id()
    new @constructor.Vertex(@, id)

  create_arc: (vertex1, vertex2, value, id=null) ->
    id ||= @next_arc_id()
    new @constructor.Arc(@, vertex1, vertex2, value, id)


  class @Vertex
    constructor: (@digraph, @id) ->
      @_arcs = []

    add_arc: (arc) ->
      @_arcs.push(arc)
      arc

    arcs: ->
      @_arcs

    find_arc: (val) ->
      for arc in @_arcs
        return arc if arc.test(val)

  class @Arc
    constructor: (@digraph, @vertex, @next_vertex, @value, @id) ->

    vertex_id: ->
      @vertex.id

    next_vertex_id: ->
      @next_vertex.id

    test: (value) ->
      @value == value

    dotString: ->
      edge = Graphviz.dotEdge(@vertex.id, @next_vertex.id)
      attrs = Graphviz.dotAttrs({label: "#{@dot_label()}"})
      "#{edge}#{attrs};\n"

     dot_label: ->
       @value.toString()

module.exports = NaiveDigraph
