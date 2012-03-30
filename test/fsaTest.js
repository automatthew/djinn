//require.paths.unshift('.');

//var vows = require("vows");
var assert = require('assert');
var FSA = require('../build/djinn').FSA;
var fs = require("fs");


//var joinLog = function (val) { console.log(val.join(""));};
//var log = function (val) { console.log(val);};


var fsa = new FSA();
fsa.add_path(["m", "a", "t", "t", "h", "e", "w"])
fsa.add_path(["m", "a", "t", "t"], 42);
var state_list = fsa.add_path("margin".split(""))
state_list[2].connect("t", state_list[1]);
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
  assert.deepEqual(x.accept_sequence("matt").path, "matt".split(""));
  // Test final state value.
  assert.deepEqual(x.accept_sequence("matt").finalValue, 42);
  assert.deepEqual(x.accept_sequence("matthew").path, "matthew".split(""));
  assert.deepEqual(x.accept_sequence("matargin").path, "matargin".split(""));
  assert.deepEqual(x.accept_sequence("mat"), false);
  assert.deepEqual(x.accept_sequence("smatty"), false);
  assert.deepEqual(x.accept_sequence("tim").path, "tim".split(""));
  assert.deepEqual(x.accept_sequence("dad").path, "dad".split(""));
  assert.deepEqual(x.accept_sequence("daddyo"), false);

  assert.deepEqual(x.accept_sequence("fan").path, "fan".split(""));
  assert.deepEqual(x.accept_sequence("fat"), false);
  assert.deepEqual(x.accept_sequence("fun").path, "fun".split(""));
  //assert.deepEqual(x.accept_sequence("ryan").path, "ryan".split(""));
}

testy(fsa);

var dump = fsa.dump();
var restored = FSA.load(dump);
//restored.graph("restored.dot");

testy(restored);

var str = fs.readFileSync("./test/curfsa.json");
var restored = FSA.load(JSON.parse(str));
//restored.graph("./test/curfsa.dot");



