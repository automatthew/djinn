Testify = require "testify"
assert = require "assert"

Digraph = require("../src/djinn").NaiveDigraph

nouns = new Digraph()
nouns.add_path("deal")
nouns.add_path("project")
nouns.add_path("sand")
nouns.add_path("clays")
nouns.add_path("river")

verbs = new Digraph()
verbs.add_path("deal")
verbs.add_path("project")
verbs.add_path("pray")
verbs.add_path("claps")
verbs.add_path("make")
verbs.add_path("sand")
verbs.add_path("sell")

inter = nouns.intersect(verbs)
inter.write_graph("inter.dot")


Testify.test "Digraph intersection", (context) ->

  context.test "Expected paths", ->
    assert.deepEqual inter.paths(), [
      "deal".split(""),
      "project".split(""),
      "cla".split(""),
      "sand".split(""),
    ]


#nouns.write_graph("nouns.dot")
#verbs.write_graph("verbs.dot")


