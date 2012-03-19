//require.paths.unshift('.');

//var vows = require("vows");
var assert = require('assert');
var FSA = require('../build/djinn').FSA;
var fs = require("fs");


//var joinLog = function (val) { console.log(val.join(""));};
//var log = function (val) { console.log(val);};


var fsa = new FSA();
fsa.addPath(["m", "a", "t", "t", "h", "e", "w"])
fsa.addPath(["m", "a", "t", "t"], 42);
var state_list = fsa.addPath("margin".split(""))
state_list[2].connect("t", state_list[1]);
fsa.addPath(["t", true, "m"])

var state_list = fsa.addPath(["d", "o", "n"])
var first = fsa.start;
var last = state_list[state_list.length - 1];
fsa.addPath("dad".split(''), null, {from: first, to: last})
fsa.addPath("ar".split(''), null, {from: state_list[1], to: state_list[2]})

fsa.addPath(["f", true, "n"])
fsa.addPath([function (v) {return true}, "y", "a", "n"])

fsa.graph("fsa.dot");

//fsa.print();

var testy = function (x) {
  assert.deepEqual(x.test("matt").path, "matt".split(""));
  // Test final state value.
  assert.deepEqual(x.test("matt").finalValue, 42);
  assert.deepEqual(x.test("matthew").path, "matthew".split(""));
  assert.deepEqual(x.test("matargin").path, "matargin".split(""));
  assert.deepEqual(x.test("mat"), false);
  assert.deepEqual(x.test("smatty"), false);
  assert.deepEqual(x.test("tim").path, "tim".split(""));
  assert.deepEqual(x.test("dad").path, "dad".split(""));

  assert.deepEqual(x.test("fan").path, "fan".split(""));
  assert.deepEqual(x.test("fat"), false);
  assert.deepEqual(x.test("fun").path, "fun".split(""));
  assert.deepEqual(x.test("ryan").path, "ryan".split(""));
}

testy(fsa);

var dump = fsa.dump();
var restored = FSA.load(dump);
//restored.graph("restored.dot");

testy(restored);

var str = fs.readFileSync("./test/curfsa.json");
var restored = FSA.load(JSON.parse(str));
//restored.graph("./test/curfsa.dot");



