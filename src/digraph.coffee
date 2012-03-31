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

    intersect: (other) ->
      # warning: Cartesian product
      arc for arc in @arcs() when other.find_arc(arc.value)

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

  # return a new digraph that is the intersection of the two graphs.  
  intersect: (other) ->
    digraph = @
    intersection = new @constructor()

    vkey = (v1, v2) ->
      "#{v1.id},#{v2.id}"
    object_pop = (obj) ->
      key = Object.keys(obj)[0]
      val = obj[key]
      delete obj[key]
      [key, val]

    unvisited_vertices = {}
    root_key = vkey(@source, other.source)
    unvisited_vertices[root_key] = [@source, other.source]
    vertex_mapper = {}
    vertex_mapper[root_key] = intersection.source

    while Object.keys(unvisited_vertices).length >0
      # "pop" a state from unvisited_vertices
      [key, [this_vertex, other_vertex]] = object_pop(unvisited_vertices)
      out_current = vertex_mapper[key]

      # for the two current states, iterate over the 
      # transitions with same values
      for this_arc in this_vertex.arcs()
        for other_arc in other_vertex.arcs() when this_arc.test(other_arc.value)
          this_next = this_arc.next_vertex
          other_next = other_arc.next_vertex

          next_key = vkey(this_next, other_next)
          # if the new graph does not already have the intersection state...
          out_next = vertex_mapper[next_key]
          if !out_next
            # create an intersection state and index it
            out_next = intersection.create_vertex()
            vertex_mapper[next_key] = out_next
            unvisited_vertices[next_key] = [this_next, other_next]
          # add the transition
          intersection.add_arc(out_current, out_next, this_arc.value)
    intersection




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


  traverse: (callback) ->
    _traverse = @stepper()
    next = _traverse([@source], callback)
    while next.length > 0
      next = _traverse(next, callback)

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
