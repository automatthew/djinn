Digraph = require("./digraph")
Graphviz = require("./graphviz")

class NaiveDigraph extends Digraph

  # extensions

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

  # customization

  next_vertex_id: ->
    @vertex_id_counter++

  next_arc_id: ->
    @arc_id_counter++


  class @Vertex
    constructor: (@digraph, id) ->
      @id = id || @digraph.next_vertex_id()
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
    constructor: (@digraph, @vertex, @value, @next_vertex) ->
      @id = @digraph.next_arc_id()

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
