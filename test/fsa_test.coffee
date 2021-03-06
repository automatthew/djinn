Testify = require "testify"
assert = require "assert"
Djinn = require "../src/djinn"
FSA = Djinn.FSA
fs = require "fs"

Testify.test "Djinn FSA", (context) ->

  fsa = new FSA()

  fsa.add_path("matthew")
  fsa.add_path("matt", 42)
  state_list = fsa.add_path("margin")
  fsa.add_arc(state_list[2], state_list[1], "z")

  fsa.add_path("did")
  state_list = fsa.add_path("don")
  first = fsa.start
  last = state_list[state_list.length - 1]
  fsa.add_path("dad", null, {from: first, to: last})
  fsa.add_path("ar".split(""), null, {from: state_list[1], to: state_list[2]})


  tests = (context, x) ->
    context.test "accepts the expected strings", (context) ->
      context.test "exact match", ->
        assert(x.accept("matt"))
        assert(x.accept("matthew"))
        assert(x.accept("dad"))
      context.test "cycles", ->
        assert(x.accept("mazatthew"))
        assert(x.accept("mazazatthew"))
        assert(x.accept("mazazazatthew"))

    context.test "rejects the expected strings", ->
      assert(!x.accept("mat"))
      assert(!x.accept("mazzatthew"))
      assert(!x.accept("smatty"))
      assert(!x.accept("daddyo"))
      assert(!x.accept("fat"))
      assert(!x.accept("do"))

    assert.deepEqual(x.match("matt").final_state.value, 42)

  context.test "Constructed from scratch", (context) ->
    tests(context, fsa)

  context.test "Dumped and restored", (context) ->
    dump = fsa.dump()
    restored = FSA.load(dump)
    tests(context, restored)
