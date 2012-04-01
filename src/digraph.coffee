Graphviz = require("./graphviz")

# Class for creating a directed graph with a global source.
# You can't use this class directly, as it lacks nested
# Vertex and Arc classes.  Extend it and define your own
# support classes, a la NaiveDigraph.
class Digraph

  constructor: () ->
    @Vertex = @constructor.Vertex
    @Arc = @constructor.Arc
    @source = @create_vertex()

  create_vertex: (id=null) ->
    new @Vertex(@, id)

  add_arc: (vertex1, vertex2, value) ->
    arc = new @Arc(vertex1, @next_arc_id(), value, vertex2)
    vertex1.add_arc(arc)

  add_path: (array, options={}) ->
    digraph = @
    first_vertex = options.from || digraph.source
    if options.to
      last_vertex = options.to
    else
      last_vertex = digraph.create_vertex()
    @connect_vertices(array, first_vertex, last_vertex)

  connect_vertices: (values, first_vertex, last_vertex) ->
    digraph = @
    vertex = first_vertex
    vertex_list = [vertex]

    # we need to treat the last value differently.
    l = values.length - 2
    if l >= 0
      for i in [0..l]
        val = values[i]
        if (arc = vertex.find_arc(val))
          vertex = arc.next_vertex
        else
          next_vertex = digraph.create_vertex()
          digraph.add_arc(vertex, next_vertex, val)
          vertex = next_vertex
        vertex_list.push(vertex)

    last_value = values[values.length - 1]
    digraph.add_arc(vertex, last_vertex, last_value)
    vertex_list.push(last_vertex)
    vertex_list

  class @IntersectionHelper
    constructor: (graph1, graph2, @intersection) ->
      @unvisited = {}
      @product_vertices = {}
      root_key = @vkey(graph1.source, graph2.source)
      @unvisited[root_key] = [graph1.source, graph2.source]
      @product_vertices[root_key] = @intersection.source

    vkey: (v1, v2) ->
      "#{v1.id},#{v2.id}"

    add_unvisited: (v1, v2, product_vertex) ->
      key = @vkey(v1, v2)
      @unvisited[key] = [v1, v2]
      @product_vertices[key] = product_vertex

    get_next_vertices: ->
      keys = Object.keys(@unvisited)
      if keys.length == 0
        null
      else
        key = keys[0]
        [v1, v2] = @unvisited[key]
        delete @unvisited[key]
        [v1, v2, @product_vertices[key]]

    # this only works if arc equivalence is assumed to mean
    # that the arcs have the same @value
    intersect_arcs: (v1, v2, callback) ->
      vals = {}
      for arc in v1.arcs()
        vals[arc.value] = arc
      for other_arc in v2.arcs()
        if (this_arc = vals[other_arc.value])
          callback(this_arc, other_arc)

    product_vertex: (v1, v2) ->
      key = @vkey(v1, v2)
      unless (vertex = @product_vertices[key])
        vertex = @intersection.intersect_vertices(v1, v2)
        @add_unvisited(v1, v2, vertex)
      vertex


  intersect_vertices: (v1, v2) ->
    # Implement sink/final checking for FSMs by
    # overriding this method and messing with the
    # vertex we create.
    @create_vertex()


  # return a new digraph that is the intersection of the two graphs.  
  # NOTE: FSM subclasses will end up with sinks that aren't final.
  intersect: (other) ->
    digraph = @
    product = new @constructor()
    helper = new @constructor.IntersectionHelper(digraph, other, product)

    while (next_vertices = helper.get_next_vertices())
      [this_vertex, other_vertex, product_vertex] = next_vertices

      # for the two current vertices, iterate over the arcs with same values.
      # TODO: check the arc intersection algorithm for stupids.
      helper.intersect_arcs this_vertex, other_vertex, (this_arc, other_arc) ->
        this_next = this_arc.next_vertex
        other_next = other_arc.next_vertex

        # if the new graph does not already have the intersection state,
        # create an intersection state and index it
        product_next = helper.product_vertex(this_next, other_next)
        product.add_arc(product_vertex, product_next, this_arc.value)
    product


  traverse: (callback) ->
    _traverse = @stepper()
    next = _traverse([@source], callback)
    while next.length > 0
      next = _traverse(next, callback)

  stepper: ->
    visited_arcs = {}
    (current, callback) ->
      next = []
      for vertex in current
        visited_arcs[vertex.id] ||= {}
        # iterate over only those arcs we haven't seen yet
        for arc in vertex.arcs() when !visited_arcs[vertex.id][arc.id]
          visited_arcs[vertex.id][arc.id] = arc
          callback(arc)
          next.push(arc.next_vertex)
      return next

  write_graph: (filename) ->
    fs = require("fs")
    string = @format_graph()

    if filename
      fs.writeFileSync(filename, string)
    string

  format_graph: ->
    string = Graphviz.digraph_preamble("Djinn")
    @traverse (arc) -> string += arc.dotString()
    #for vertex in @final_states
      #node = Graphviz.dotNode(vertex.id, {shape: "doublecircle"}
      #string += node

    string += "}\n"
    string

  dump: (callback) ->
    data = {transitions: []}
    transitions = data.transitions

    @traverse (arc) ->
      callback(arc) if callback
      transitions.push
        vertex: arc.vertex.id
        next: arc.next_vertex.id
        val: arc.value

    data.vertex_id_counter = this.vertex_id_counter
    data.arc_id_counter = this.arc_id_counter
    data

  @load: (args...) ->
    new @().load(args...)

  load: (dump, transition_callback, states_callback) ->
    digraph = @
    transitions = dump.transitions
    tmpStates = {}
    tmpStates[digraph.source.id] = digraph.source

    for transition in transitions
      tmpStates[transition.vertex] ||= digraph.create_vertex(transition.vertex)
      tmpStates[transition.next] ||= digraph.create_vertex(transition.next)
      current = tmpStates[transition.vertex]
      next = tmpStates[transition.next]
      digraph.add_arc(current, next, transition.val)
      callback(transition) if transition_callback
    digraph.vertex_id_counter = dump.vertex_id_counter
    digraph.arc_id_counter = dump.arc_id_counter
    states_callback(tmpStates) if states_callback
    @

module.exports = Digraph
