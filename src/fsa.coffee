Digraph = require("./digraph")

class SequenceAcceptor extends Digraph

  class @Arc extends Digraph.Arc

    equiv: (value) ->
      @value == value || @value == true

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

  accept: (sequence) ->
    for tracker in @try_sequence(sequence)
      return true if tracker.state.value

  match: (sequence) ->
    list = @try_sequence(sequence)
    matches = @compile_matches(list)
    matches[0] || false

  matches: (sequence) ->
    list = @try_sequence(sequence)
    matches = @compile_matches(list)

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
    matches


class MatchTracker
  constructor: (@parent, @state, @val) ->

  track: (state, val) ->
    new MatchTracker(@, state, val)


module.exports = SequenceAcceptor
