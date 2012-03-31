Graphviz = require("./graphviz")

# Class for creating a directed graph with a global source.
# Something like a tree that allows cycles.
class Digraph

  class @Vertex
    constructor: (@id) ->
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
      output = "#{edge}#{attrs};\n"
      #if @next_vertex.sink
        #node = Graphviz.dotNode(@next_vertex.id, {shape: "doublecircle"})
        #output += node

      output

     dot_label: ->
       @value.toString()


  constructor: () ->
    @vertex_id_counter = 0
    @arc_id_counter = 0
    @source = @create_vertex()

  next_vertex_id: ->
    @vertex_id_counter++

  next_arc_id: ->
    @arc_id_counter++

  create_vertex: (id) ->
    id ||= @next_vertex_id()
    new @constructor.Vertex(id)

  add_arc: (vertex1, vertex2, value) ->
    arc = new @constructor.Arc(vertex1, @next_arc_id(), value, vertex2)
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

    product_vertex: (v1, v2) ->
      key = @vkey(v1, v2)
      unless (vertex = @product_vertices[key])
        # Implement sink/final checking for FSMs by
        # overriding this method and messing with the
        # vertex we create.
        vertex = @intersection.create_vertex()
        @add_unvisited(v1, v2, vertex)
      vertex

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
    intersecting_arcs: (v1, v2, callback) ->
      vals = {}
      for arc in v1.arcs()
        vals[arc.value] = arc
      for other_arc in v2.arcs()
        if (this_arc = vals[other_arc.value])
          callback(this_arc, other_arc)



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
      helper.intersecting_arcs this_vertex, other_vertex, (this_arc, other_arc) ->
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
    string = Graphviz.digraph_preamble("Djinn")

    @traverse (arc) -> string += arc.dotString()

    string += "}\n"

    if filename
      fs.writeFileSync(filename, string)
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
