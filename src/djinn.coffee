# Sort of based on http://swtch.com/~rsc/regexp/regexp1.html
# But also sort of not.
# Some influence contributed by AT&T's fsm lib


# Graphviz formatting helpers

Graphviz =
  dotEdge: (from, to) ->
    [from, to].join(" -> ")

  dotNode: (node, attrs) ->
    "#{node}#{@dotAttrs(attrs)};\n"

  dotAttrs: (obj) ->
    pairs = []
    pairs = ("#{key}=\"#{val}\"" for own key, val of obj)
    " [#{pairs.join(", ")}]"


step = (current, val) ->
  next = {size: 0}
  for own id, thing of current when id != "size"
    state = thing[0]
    state.arcs.forEach (arc) ->
      if arc.test(val)
        leaf = new TreeNode(thing[1], val)
        if arc.nextState.final
          leaf.final = true
        else
          null
        next[arc.nextState.id] = [arc.nextState, leaf]
        next.size++
  next


testMatch = (list, val) ->
  match = false
  for own id, thing of list
    state = thing[0]
    if state && state.finalValue
      tip = thing[1]
      path = [tip.val]
      t = null
      while (t = tip.parent)
        if t.val
          path.unshift(t.val)
        tip = t
      match = [path, state.finalValue]
  match

class State

  constructor: (@id, @finalValue) ->
    @arcs = []

  connect: (val, nextState) ->
    arc = new Arc(@, val, nextState)
    @arcs.push(arc)
    arc

  findArc: (val) ->
    for arc in @arcs
      return arc if arc.val == val


class Arc

  constructor: (@state, @val, @nextState) ->
    if typeof(@val) == "function"
      @test = @val
    @nextState ||= null

  # It would be more fun if this were derived from the FSA somehow
  test: (val) ->
    @val == val || @val == true

  dotString: ->
    str = ""
    v = @formatTest(@val)
    if @nextState.finalValue
      str += Graphviz.dotNode(@nextState.id, {shape: "doublecircle"})
    str += "#{Graphviz.dotEdge(@state.id, @nextState.id)}#{Graphviz.dotAttrs({label: v})};\n"
    str

  formatTest: (val) ->
    if typeof(val) == "function"
      "<function>"
    else if val == true
      return "<epsilon>"
    else
      val

class TreeNode

  constructor: (parent, @val, @children) ->
    if parent
      @parent = parent
      @parent.children.push(@)
    @children ||= []
    @final = false



class FSA

  constructor: ->
    @stateIdCounter = 0
    @start = @createState()
    @finals = {}

  getStateId: ->
    @stateIdCounter++

  createState: (opts) ->
    opts ||= {}
    id = opts.id || @getStateId()
    new State(id, opts.value)

  finalize: (state, value) ->
    state.finalValue = value || true
    @finals[state.id] = state

  finalStates: ->
    out = []
    for id in finals
      if finals.hasOwnProperty(id)
        out.push(finals[id])
    out


  test: (sequence) ->
    state1 = @start
    current = {}
    next = {}
    tree = new TreeNode(null, null)
    current[state1.id] = [state1, tree]
    for i in [0..sequence.length]
      val = sequence[i]
      next = step(current, val)
      if next.length == 0
        return testMatch(current, val)
      else if i == sequence.length - 1
        return testMatch(next, val)
      else
        current = next


  addPath: (array, finalValue) ->
    fsa = @
    state1 = fsa.start
    ns = null

    for val in array
      arc = state1.findArc(val)
      if arc
        state1 = arc.nextState
      else
        ns = fsa.createState()
        state1.connect(val, ns)
        state1 = ns

    # FIXME: if the state is already final, we duplicate it
    # in the FSM's finalStates array.
    fsa.finalize(state1, finalValue)
    fsa

  traverse: (fn) ->
    queue = []
    finalStates = []
    nextState = null
    arc = null
    queue = queue.concat(@start.arcs)

    while queue.length > 0
      arc = queue.shift()
      nextState = arc.nextState
      if nextState.finalValue
        finalStates.push(nextState)
      fn(arc)
      queue = queue.concat(arc.nextState.arcs)

    return finalStates


  print: ->
    finalStates = @traverse (arc) ->
      console.log(arc.state.id, arc.nextState.id, arc.val)
    for state in finalStates
      console.log state.id


  dump: ->
    data = {transitions: []}
    transitions = data.transitions

    finalStates = @traverse (arc) ->
      transitions.push
        state: arc.state.id
        next: arc.nextState.id
        val: arc.val

    data.finalStates = finalStates.map (s) -> {id: s.id, value: s.finalValue}
    data.stateIdCounter = this.stateIdCounter
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
    fsa.stateIdCounter = dump.stateIdCounter
    fsa


  graph: (filename) ->
    fs = require("fs")
    string =
      """
      digraph finite_state_machine {\n
      rankdir=LR;\n
      """

    @traverse2 (arc) ->
      string += arc.dotString()

    string += "}\n"

    if filename
      fs.writeFileSync(filename, string)
    string


  traverse2: (fn) ->
    current = {}
    next = {}
    current[@start.id] = @start
    seenStates = {}
    step2 = (current, callback) ->
      next = {}
      for own id, state of current
        seenStates[state.id] = seenStates[state.id] || {}
        state.arcs.forEach (arc) ->
          # circularity bug.
          # FIXME:  arc.val does not determine arc.
          # need to check target state, too.
          if !seenStates[state.id][arc.val]
            seenStates[state.id][arc.val] = arc
            callback(arc)
            next[arc.nextState.id] = arc.nextState
      for key, val of next
        return next
      return false

    next = step2(current, fn);
    while next
      current = next
      next = step2(current, fn)




exports.FSA = FSA
