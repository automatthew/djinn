# Sort of based on http://swtch.com/~rsc/regexp/regexp1.html
# But also sort of not.
# Some influence contributed by AT&T's fsm lib

Graphviz = require("./graphviz")

class Digraph

  constructor: (@vertex_class, @arc_class) ->
    @vertex_id_counter = 0
    @arc_id_counter = 0
    @source = @create_vertex()

  next_vertex_id: ->
    @vertex_id_counter++

  next_arc_id: ->
    @arc_id_counter++

  # FIXME: why use opts instead of two args?
  create_vertex: (opts) ->
    opts ||= {}
    id = opts.id || @next_vertex_id()
    new @vertex_class(@, opts.value)

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
          vertex.connect(val, next_vertex)
          vertex = next_vertex
        vertex_list.push(vertex)

    last_value = values[values.length - 1]
    vertex.connect(last_value, last_vertex)
    vertex_list.push(last_vertex)
    vertex_list

  stepper: ->
    visited_arcs = {}
    (current, callback) ->
      next = []
      for vertex in current
        visited_arcs[vertex.id] ||= {}
        # iterate over only those arcs we haven't seen yet
        for arc in vertex.arcs when !visited_arcs[vertex.id][arc.id]
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

  @load: (dump, transition_callback, states_callback) ->
    transitions = dump.transitions
    digraph = new @()
    tmpStates = {}
    tmpStates[digraph.source.id] = digraph.source

    for transition in transitions
      tmpStates[transition.vertex] ||= digraph.create_vertex({id: transition.vertex})
      tmpStates[transition.next] ||= digraph.create_vertex({id: transition.next})
      current = tmpStates[transition.vertex]
      next = tmpStates[transition.next]
      current.connect(transition.val, next)
      callback(transition) if transition_callback
    digraph.vertex_id_counter = dump.vertex_id_counter
    digraph.arc_id_counter = dump.arc_id_counter
    states_callback(tmpStates) if states_callback
    digraph

class FSA extends Digraph

  constructor: ->
    super(State, Arc)
    @final_states = {}

  finalize: (state, value) ->
    state.finalValue = value || true
    @final_states[state.id] = state

  add_path: (array, finalValue, options={}) ->
    vertices = super(array, options)
    @finalize(vertices[vertices.length-1], finalValue)
    vertices

  print_att: ->
    output = @format_att()
    console.log(output.join("\n"))

  # TODO: is this even correct for AT&T fsm anymore?
  format_att: ->
    final_states = []
    output = []
    @traverse (arc) ->
      if arc.next_vertex.finalValue
        final_states.push(arc.next_vertex)
      output.push(arc.print())
    for vertex in final_states
      output.push(vertex.id)
    output


  dump: ->
    final_states = []
    data = super (arc) ->
      if arc.next_vertex.finalValue
        state = arc.next_vertex
        final_states.push({id: state.id, value: state.finalValue})

    data.final_states = final_states
    data

  @load: (dump) ->
    tmp_states = null
    fsa = super dump, null, (states) ->
      tmp_states = states

    for state in dump.final_states
      vertex = tmp_states[state.id]
      fsa.finalize(vertex, state.value)

    fsa

  accept_sequence: (sequence) ->
    state = @source
    tracker = new PathTracker()
    current = [{state: state, tracker: tracker}]
    sequence_length = sequence.length - 1
    for i in [0..sequence_length]
      val = sequence[i]
      next = []
      for stage in current
        next = next.concat(stage.state.test(val, stage.tracker))

      if i == sequence_length
        return matched_path(next, val)
      else if next.length == 0
        return false
      else
        current = next


# TODO: we return either false or an object.  I don't like this.
matched_path = (list, val) ->
  match = false
  for stage in list
    state = stage.state
    if state && state.finalValue
      tip = stage.tracker
      path = [tip.val]
      # backtrack up the tree to find the path that matched
      while (tip = tip.parent)
        path.unshift(tip.val) if tip.val
      match = { path: path, finalValue: state.finalValue }
  match

class PathTracker

  constructor: (@parent, @val) ->

  next: (val) ->
    new PathTracker(@, val)

class State
  constructor: (@digraph, @finalValue) ->
    @arc_class = @digraph.arc_class
    @id = @digraph.next_vertex_id()
    @arcs = []

  connect: (val, next_vertex) ->
    arc = new @arc_class(@, @digraph.next_arc_id(), val, next_vertex)
    @arcs.push(arc)
    arc

  find_arc: (val) ->
    for arc in @arcs
      return arc if arc.value == val

  test: (val, tracker) ->
    stages = []
    for arc in @arcs when arc.test(val)
      stages.push
        state: arc.next_vertex
        tracker: tracker.next(val)
    stages


class Arc
  constructor: (@vertex, @id, @value, @next_vertex) ->
    @next_vertex ||= null

  # It would be more fun if this were derived from the FSA somehow
  test: (value) ->
    @value == value || @value == true

  print: ->
    "#{@vertex.id} #{@next_vertex.id} #{@formatValue(@value)}"

  dotString: ->
    v = @formatValue(@value)
    edge = Graphviz.dotEdge(@vertex.id, @next_vertex.id)
    attrs = Graphviz.dotAttrs({label: "#{v}"})
    output = "#{edge}#{attrs};\n"
    if @next_vertex.finalValue
      node = Graphviz.dotNode(@next_vertex.id, {shape: "doublecircle"})
      output += node

    output

  formatValue: (value) ->
    if typeof(value) == "function"
      "<lambda>"
    else if value == true
      return "<epsilon>"
    else
      value






exports.FSA = FSA
