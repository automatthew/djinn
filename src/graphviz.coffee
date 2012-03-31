
# Graphviz formatting helpers

Graphviz =
  digraph_preamble: (name) ->
    """
    digraph #{name} {\n
    rankdir=LR;\n
    node [shape=circle,fontsize=10]
    edge [fontsize=16]
    """
  
  dotEdge: (from, to) ->
    [from, to].join(" -> ")

  dotNode: (node, attrs) ->
    "#{node}#{@dotAttrs(attrs)};\n"

  dotAttrs: (obj) ->
    pairs = []
    pairs = ("#{key}=\"#{val}\"" for own key, val of obj)
    " [#{pairs.join(", ")}]"

module.exports = Graphviz
