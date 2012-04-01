Digraph = require("./digraph")
Graphviz = require("./graphviz")

class NaiveDigraph extends Digraph

  constructor: () ->
    super()
    @vertex_id_counter = 0
    @arc_id_counter = 0

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
    constructor: (@vertex, @id, @value, @next_vertex) ->

    test: (value) ->
      @value == value

    dotString: ->
      edge = Graphviz.dotEdge(@vertex.id, @next_vertex.id)
      attrs = Graphviz.dotAttrs({label: "#{@dot_label()}"})
      "#{edge}#{attrs};\n"

     dot_label: ->
       @value.toString()

module.exports = NaiveDigraph
