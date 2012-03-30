Graphviz = require("./graphviz")

class TreeNode

  constructor: (parent, @val, @children) ->
    if parent
      @parent = parent
      @parent.children.push(@)
    @children ||= []
    @final = false



step = (current, val) ->
  next = {size: 0}
  for own key, thing of current when key != "size"
    thing.state.arcs.forEach (arc) ->
      if arc.test(val)
        node = new TreeNode(thing.tree, val)
        if arc.next_vertex.final
          next.found_match = true
        else
          null
        next[arc.next_vertex.id] = {state: arc.next_vertex, tree: node}
        next.size++
  next


match_path = (list, val) ->
  match = false
  for own id, thing of list
    state = thing.state
    if state && state.finalValue
      tip = thing.tree
      path = [tip.val]
      t = null
      # backtrack up the graph to find the path that
      # matched
      # TODO/FIXME: what happens if graph is cyclic?
      while (tip = tip.parent)
        if tip.val
          path.unshift(tip.val)
      match = { path: path, finalValue: state.finalValue }
  match



class FSA

  constructor: ->
    @state_id_counter = 0
    @arc_id_counter = 0
    @start = @createState()
    @finals = {}

  next_state_id: ->
    @state_id_counter++

  next_arc_id: ->
    @arc_id_counter++

  createState: (opts) ->
    opts ||= {}
    id = opts.id || @next_state_id()
    new State(@, opts.value)

  finalize: (state, value) ->
    state.finalValue = value || true
    @finals[state.id] = state

  finalStates: ->
    state for own id, state of finals

  test: (sequence) ->
    state = @start
    current = {}
    next = {}
    node = new TreeNode()
    current[state.id] = {state: state, tree: node}
    for i in [0..sequence.length-1]
      val = sequence[i]
      next = step(current, val)
      # TODO: this looks fishy.
      if next.found_match
        return match_path(current, val)
      else if i == sequence.length - 1
        return match_path(next, val)
      else
        current = next


  addPath: (array, finalValue, options={}) ->
    fsa = @
    first_state = options.from || fsa.start
    if options.to
      last_state = options.to
    else
      last_state = fsa.createState()
      fsa.finalize(last_state, finalValue)

    @connect_states(array, first_state, last_state)

class State

  constructor: (@fsa, @finalValue) ->
    @id = @fsa.next_state_id()
    @arcs = []

  connect: (val, nextState) ->
    arc = new Arc(@, @fsa.next_arc_id(), val, nextState)
    @arcs.push(arc)
    arc

  findArc: (val) ->
    for arc in @arcs
      return arc if arc.value == val


class Arc

  constructor: (@state, @id, @value, @nextState) ->
    if typeof(@value) == "function"
      @test = @value
    @nextState ||= null

  # It would be more fun if this were derived from the FSA somehow
  test: (value) ->
    @value == value || @value == true

  print: ->
    "#{@state.id} #{@nextState.id} #{@value}"


  dotString: ->
    v = @formatValue(@value)
    edge = Graphviz.dotEdge(@state.id, @nextState.id)
    attrs = Graphviz.dotAttrs({label: "#{v}"})
    output = "#{edge}#{attrs};\n"
    if @nextState.finalValue
      node = Graphviz.dotNode(@nextState.id, {shape: "doublecircle"})
      output += node

    output

  formatValue: (value) ->
    if typeof(value) == "function"
      "<lambda>"
    else if value == true
      return "<epsilon>"
    else
      value


  connect_states: (array, first_state, last_state) ->
    fsa = @
    state = first_state
    state_list = [state]

    l = array.length - 2
    if l >= 0
      for i in [0..l]
        val = array[i]
        arc = state.findArc(val)
        if arc
          state = arc.nextState
        else
          next_state = fsa.createState()
          state.connect(val, next_state)
          state = next_state
        state_list.push(state)

    last_val = array[array.length - 1]
    state.connect(last_val, last_state)
    state_list.push(last_state)
    state_list


  traverse: (callback) ->
    current = {}
    current[@start.id] = @start

    next = {}
    visitedStates = {}
    step2 = (current, callback) ->
      next = {}
      for own id, state of current
        visitedStates[state.id] = visitedStates[state.id] || {}
        state.arcs.forEach (arc) ->
          if visitedStates[state.id][arc.id]
            #console.log "skipping {#{arc.id}}"
          else
            #key = "#{arc.value},#{arc.nextState.id}"
            #console.log "visiting {#{key}}"
            visitedStates[state.id][arc.id] = arc
            callback(arc)
            next[arc.nextState.id] = arc.nextState

      if Object.keys(next).length > 0
        return next
      else
        return false

    next = step2(current, callback)
    while next
      current = next
      next = step2(current, callback)

  print: ->
    finalStates = []
    output = []
    @traverse (arc) ->
      if arc.nextState.finalValue
        finalStates.push(arc.nextState)
      output.push(arc.print())
    for state in finalStates
      output.push(state.id)

    console.log(output.join("\n"))


  dump: ->
    data = {transitions: []}
    transitions = data.transitions

    finalStates = []

    @traverse (arc) ->
      if arc.nextState.finalValue
        finalStates.push(arc.nextState)
      transitions.push
        state: arc.state.id
        next: arc.nextState.id
        val: arc.value

    data.finalStates = finalStates.map (s) -> {id: s.id, value: s.finalValue}
    data.state_id_counter = this.state_id_counter
    data

  @load: (dump) ->
    transitions = dump.transitions
    fsa = new FSA()
    tmpStates = {}
    tmpStates[fsa.start.id] = fsa.start

    for trans in transitions
      tmpStates[trans.state] ||= fsa.createState({id: trans.state})
      tmpStates[trans.next] ||= fsa.createState({id: trans.next})
      current = tmpStates[trans.state]
      next = tmpStates[trans.next]
      current.connect(trans.val, next)
    for s in dump.finalStates
      state = tmpStates[s.id]
      fsa.finalize(state, s.value)
    fsa.state_id_counter = dump.state_id_counter
    fsa


  graph: (filename) ->
    fs = require("fs")
    string =
      """
      digraph finite_state_machine {\n
      rankdir=LR;\n
      """

    @traverse (arc) ->
      string += arc.dotString()

    string += "}\n"

    if filename
      fs.writeFileSync(filename, string)
    string

  old_traverse: (callback) ->
    queue = @start.arcs.slice()
    finalStates = []
    nextState = null
    arc = null

    while queue.length > 0
      arc = queue.shift()
      nextState = arc.nextState
      if nextState.finalValue
        finalStates.push(nextState)
      callback(arc)
      queue = queue.concat(arc.nextState.arcs)
    return finalStates
