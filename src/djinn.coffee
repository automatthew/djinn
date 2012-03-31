# Sort of based on http://swtch.com/~rsc/regexp/regexp1.html
# But also sort of not.
# Some influence contributed by AT&T's fsm lib

Graphviz = require("./graphviz")

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
        return arc if arc.value == val

  class @Arc
    constructor: (@vertex, @id, @value, @next_vertex) ->
      @next_vertex ||= null

    equiv: (value) ->
      @value == value || @value == true

    dotString: ->
      edge = Graphviz.dotEdge(@vertex.id, @next_vertex.id)
      attrs = Graphviz.dotAttrs({label: "#{@dot_label()}"})
      output = "#{edge}#{attrs};\n"
      if @next_vertex.value
        node = Graphviz.dotNode(@next_vertex.id, {shape: "doublecircle"})
        output += node

      output


  constructor: () ->
    @vertex_id_counter = 0
    @arc_id_counter = 0
    @source = @create_vertex()

  next_vertex_id: ->
    @vertex_id_counter++

  next_arc_id: ->
    @arc_id_counter++

  create_vertex: (opts) ->
    opts ||= {}
    new @constructor.Vertex(@next_vertex_id(), opts.value)

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

  graph: (filename) ->
    fs = require("fs")
    string =
      """
      digraph finite_state_machine {\n
      rankdir=LR;\n
      """
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

  load: (dump, transition_callback, states_callback) ->
    digraph = @
    transitions = dump.transitions
    tmpStates = {}
    tmpStates[digraph.source.id] = digraph.source

    for transition in transitions
      tmpStates[transition.vertex] ||= digraph.create_vertex({id: transition.vertex})
      tmpStates[transition.next] ||= digraph.create_vertex({id: transition.next})
      current = tmpStates[transition.vertex]
      next = tmpStates[transition.next]
      digraph.add_arc(current, next, transition.val)
      callback(transition) if transition_callback
    digraph.vertex_id_counter = dump.vertex_id_counter
    digraph.arc_id_counter = dump.arc_id_counter
    states_callback(tmpStates) if states_callback
    @

  @load: (args...) ->
    new @().load(args...)


class FSA extends Digraph

  class @Arc extends Digraph.Arc

    # expected by Arc interface
    dot_label: ->
      @formatValue(@value)

    formatValue: (value) ->
      if typeof(value) == "function"
        "<lambda>"
      else if value == true
        return "<epsilon>"
      else
        value

    format_att: ->
      "#{@vertex.id} #{@next_vertex.id} #{@formatValue(@value)}"


  constructor: ->
    super()
    @final_states = {}

  finalize: (state, value) ->
    state.value = value || true
    @final_states[state.id] = state

  add_path: (array, value, options={}) ->
    vertices = super(array, options)
    @finalize(vertices[vertices.length-1], value)
    vertices

  print_att: ->
    output = @format_att()
    console.log(output.join("\n"))

  # TODO: is this even correct for AT&T fsm anymore?
  format_att: ->
    final_states = []
    output = []
    @traverse (arc) ->
      if arc.next_vertex.value
        final_states.push(arc.next_vertex)
      output.push(arc.format_att())
    for vertex in final_states
      output.push(vertex.id)
    output

  dump: ->
    final_states = []
    data = super (arc) ->
      if arc.next_vertex.value
        state = arc.next_vertex
        final_states.push({id: state.id, value: state.value})

    data.final_states = final_states
    data

  load: (dump) ->
    fsa = @
    super dump, null, (all_states) ->
      for state in dump.final_states
        vertex = all_states[state.id]
        fsa.finalize(vertex, state.value)
    @

  accept_sequence: (sequence) ->
    for tracker in @try_sequence(sequence)
      return true if tracker.state.value

  match_sequence: (sequence) ->
    list = @try_sequence(sequence)
    @compile_matches(list)

  try_sequence: (sequence) ->
    state = @source
    current = [new MatchTracker(null, state)]

    sequence_length = sequence.length - 1
    for i in [0..sequence_length]
      val = sequence[i]
      next = []
      for tracker in current
        for arc in tracker.state.arcs() when arc.equiv(val)
          next.push(tracker.track(arc.next_vertex, arc.value))

      if i == sequence_length
        return next
      else if next.length == 0
        return false
      else
        current = next

  compile_matches: (list, val) ->
    match = false
    matches = []
    for tracker in list
      state = tracker.state
      if state.value
        path = [tracker.val]
        # backtrack up the tree to find the path that matched
        while (tracker = tracker.parent)
          # TODO: this is skeezy.  The only tracker that should
          # not have a value is the root of the tree.
          path.unshift(tracker.val) if tracker.val
        match = { path: path, final_state: state }
        matches.push(match)
    matches[0] || false


class MatchTracker
  constructor: (@parent, @state, @val) ->

  track: (state, val) ->
    new MatchTracker(@, state, val)





exports.FSA = FSA
