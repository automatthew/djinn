
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

module.exports = Graphviz
