// Sort of based on http://swtch.com/~rsc/regexp/regexp1.html
// But also sort of not.
// Some influence contributed by AT&T's fsm lib

var util = require("util");

var FSA = exports.FSA = function FSA () {
  this.stateIdCounter = 0;
  this.start = this.createState();
  this.finals = {};
};

FSA.prototype.getStateId = function getStateId () {
  return this.stateIdCounter++;
}

FSA.prototype.createState = function createState (opts) {
  opts = opts || {};
  var id = opts["id"] || this.getStateId();
  return new State(id, opts.value);
};

FSA.prototype.finalize = function finalize (state, value) {
  state.finalValue = value || true;
  this.finals[state.id] = state;
};

FSA.prototype.finalStates = function finalStates () {
  var finals = this.finals;
  var out = [];
  for (id in finals) {
    if (finals.hasOwnProperty(id)) {
      out.push(finals[id]);
    }
  }
  return out;
};

var State = function State (id, finalValue) {
  this.id = id;
  this.arcs = [];
  this.finalValue = finalValue;
};


State.prototype.connect = function connect (val, nextState) {
  var a = new Arc(this, val, nextState);
  this.arcs.push(a);
  return a;
};

State.prototype.findArc = function findArc (val) {
  for (var i=0,l=this.arcs.length;i<l;i++) {
    if (this.arcs[i].val === val) { return this.arcs[i]; }
  }
};

var Arc = function Arc (state, val, nextState) {
  this.state = state;
  if (typeof(val) === "function") {
    this.test = val
  }
  this.val = val;
  this.nextState = nextState || null;
};

// It would be more fun if this were derived from the FSA somehow
Arc.prototype.test = function test (val) {
  return this.val === val || this.val === true;
};

Arc.prototype.dotString = function dotString () {
  var str = "";
  var v = this.formatTest(this.val);
  if (this.nextState.finalValue) { str += dotNode(this.nextState.id, {shape: "doublecircle"}); }
  str += dotEdge(this.state.id, this.nextState.id) + dotAttrs({label:v}) + ";\n";
  return str;
};

Arc.prototype.formatTest = function formatTest (val) {
  if (typeof(val) === "function") {
    return "<function>";
  } else if (val === true) {
    return "<epsilon>";
  } else {
    return val;
  }
};

var dotEdge = function dotEdge (from, to) {
  return [from, to].join(" -> ");
};

var dotNode = function dotNode (node, attrs) {
  var str = "";
  str += node;
  str += dotAttrs(attrs) + ";\n";
  return str;
};

var dotAttrs = function dotAttrs (obj) {
  var pairs = [];
  for (var key in obj) {
    if (!obj.hasOwnProperty(key)) { continue }
    pairs.push(key+'='+'"'+obj[key]+'"');
  }
  return " [" + pairs.join(", ") + "]";
};

var TreeNode = exports.TreeNode = function TreeNode (parent, val, children) {
  if (parent) {
    this.parent = parent;
    this.parent.children.push(this);
  }
  this.val = val;
  this.children = children || [];
  this.final = false;
};

FSA.prototype.test = function test (sequence) {
  var state1 = this.start;
  var current = {}, next = {};
  var tree = new TreeNode(null, val);
  current[state1.id] = [state1, tree];

  for (var i=0,l=sequence.length;i<l;i++) {
    var val = sequence[i];
    next = step(current, val);
    if (next.length === 0) {
      return testMatch(current, val);
    } else if (i === l-1) {
      return testMatch(next, val)
    } else {
      current = next;
    }
  }
};


var step = function (current, val) {
  var next = {length:0};
  for (var id in current) {
    if (current.hasOwnProperty(id) && id !== "length") {
      var state = current[id][0];
      state.arcs.forEach(function (arc) {
        if (arc.test(val)) {
          var leaf = new TreeNode(current[id][1], val);
          arc.nextState.final ? leaf.final = true : null ;
          next[arc.nextState.id] = [arc.nextState, leaf];
          next.length++;
        }
      });
    }
  }
  return next;
};

var testMatch = function (list, val) {
  var match = false;
  for (var id in list) {
    if (!list.hasOwnProperty(id)) { continue }
    var state = list[id][0];
    if (state && state.finalValue) {
      var tip = list[id][1];
      var path = [tip.val];
      var t;
      while (t = tip.parent) {
        if (t.val) { path.unshift(t.val); }
        tip = t;
      }
      match = [path, state.finalValue];
    }
  }
  return match;
}

FSA.prototype.addPath = function (array, finalValue) {
  var fsa = this;
  var state1 = fsa.start;
  var ns;
  for (var i=0, l=array.length; i<l; i++) {
    var val = array[i];
    var arc = state1.findArc(val);
    if (arc) {
      state1 = arc.nextState;
    } else {
      ns = fsa.createState();
      state1.connect(val, ns);
      state1 = ns;
    }
  }
  // FIXME: if the state is already final, we duplicate it
  // in the FSM's finalStates array.
  fsa.finalize(state1, finalValue);
  return fsa;
};


FSA.prototype.traverse = function (fn) {
  var queue = [];
  var finalStates = [];
  var nextState;
  var arc;

  queue = queue.concat(this.start.arcs);

  while (queue.length > 0) {
    arc = queue.shift();
    nextState = arc.nextState;
    if (nextState.finalValue) { finalStates.push(nextState) }
    fn(arc)
    queue = queue.concat(arc.nextState.arcs);
  }
  return finalStates;
};

FSA.prototype.traverse2 = function (fn) {
  var current = {}, next = {};
  current[this.start.id] = this.start;
  var seenStates = {};

  var step2 = function (current, fn) {
    var next = {};
    for (var id in current) {
      if (current.hasOwnProperty(id)) {
        var state = current[id];
        seenStates[state.id] = seenStates[state.id] || {};
        state.arcs.forEach(function (arc) {
          // circularity bug.
          // FIXME:  arc.val does not determine arc.
          // need to check target state, too.
          if (!seenStates[state.id][arc.val]) {
            seenStates[state.id][arc.val] = arc;
            fn(arc);
            next[arc.nextState.id] = arc.nextState;
          }
        });
      }
    }
    // Warning: clever.
    for (i in next) { return next; }
    return false;
  };

  next = step2(current, fn);
  while (next) {
    current = next;
    next = step2(current, fn);
  }
};

FSA.load = function (dump) {
  var transitions = dump.transitions;
  var fsa = new FSA();
  var tmpStates = {};
  tmpStates[fsa.start.id] = fsa.start;

  transitions.forEach(function (trans) {
    tmpStates[trans.state] = tmpStates[trans.state] || fsa.createState({id: trans.state});
    tmpStates[trans.next] = tmpStates[trans.next] || fsa.createState({id: trans.next});
    var current = tmpStates[trans.state];
    var next = tmpStates[trans.next];
    current.connect(trans.val, next);
  });
  dump.finalStates.forEach(function (s) {
    var state = tmpStates[s.id]
    fsa.finalize(state, s.value);
  });
  fsa.stateIdCounter = dump.stateIdCounter;
  return fsa;
};

FSA.prototype.dump = function () {
  var data = {transitions: []};
  var transitions = data.transitions;

  var finalStates = this.traverse(function (arc) {
    var trans = {
      state: arc.state.id,
      next: arc.nextState.id,
      val: arc.val,
    };
    transitions.push(trans);
  });
  data.finalStates = finalStates.map(function (s) {return {id:s.id, value: s.finalValue}});
  data.stateIdCounter = this.stateIdCounter;
  return data;
};

FSA.prototype.print = function () {
  var finalStates = this.traverse(function (arc) {
    console.log(arc.state.id, arc.nextState.id, arc.val);
  });
  for (var i=0,l=finalStates.length; i<l; i++) { console.log(finalStates[i].id) }
}

FSA.prototype.graph = function (filename) {
  var fs = require("fs");
  var graph = "digraph finite_state_machine {\n";
  graph += "rankdir=LR;\n";

  var finalStates = this.traverse2(function (arc) {
    graph += arc.dotString();
  });

  graph += "}\n";
  if (filename) {
    fs.writeFileSync(filename, graph);
  }
  return graph;
};


