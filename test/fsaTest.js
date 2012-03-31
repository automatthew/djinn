//require.paths.unshift('.');

//var vows = require("vows");
var assert = require('assert');
var FSA = require('../build/djinn').FSA;
var fs = require("fs");


//var joinLog = function (val) { console.log(val.join(""));};
//var log = function (val) { console.log(val);};


var fsa = new FSA();
fsa.add_path(["m", "a", "t", "t", "h", "e", "w"])
fsa.add_path(["m", "a", "t", "t", true, "e", "w"])
fsa.add_path(["m", "a", "t", "t"], 42);
var state_list = fsa.add_path("margin".split(""))
fsa.add_arc(state_list[2], state_list[1], "t")
fsa.add_path(["t", true, "m"])

var state_list = fsa.add_path(["d", "o", "n"])
var first = fsa.start;
var last = state_list[state_list.length - 1];
fsa.add_path("dad".split(''), null, {from: first, to: last})
fsa.add_path("ar".split(''), null, {from: state_list[1], to: state_list[2]})

fsa.add_path(["f", true, "n"])
//fsa.add_path([function (v) {return true}, "y", "a", "n"])

fsa.graph("fsa.dot");

//fsa.print_att();

var testy = function (x) {
  assert(x.accept_sequence("matt"));
  assert(x.accept_sequence("matthew"));
  assert(x.accept_sequence("matargin"));
  assert(x.accept_sequence("tim"));
  assert(x.accept_sequence("dad"));
  assert(x.accept_sequence("fan"));

  assert(!x.accept_sequence("mat"));
  assert(!x.accept_sequence("smatty"));
  assert(!x.accept_sequence("daddyo"));
  assert(!x.accept_sequence("fat"));

  assert.deepEqual(x.match_sequence("matt").final_state.value, 42);
  assert.deepEqual(x.match_sequence("tim").path, ["t", true, "m"]);
}

testy(fsa);

var dump = fsa.dump();
var restored = FSA.load(dump);
//restored.graph("restored.dot");

testy(restored);

var str = fs.readFileSync("./test/curfsa.json");
var restored = FSA.load(JSON.parse(str));
//restored.graph("./test/curfsa.dot");



