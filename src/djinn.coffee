# Sort of based on http://swtch.com/~rsc/regexp/regexp1.html
# But also sort of not.
# Some influence contributed by AT&T's fsm lib

module.exports =
  "Digraph": require("./digraph")
  "NaiveDigraph": require("./naive_digraph")
  "FSA": require("./fsa")



