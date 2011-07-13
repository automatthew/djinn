require.paths.unshift('.');

//var vows = require("vows");
var assert = require('assert');
var FSA = require('fsa').FSA;
var fs = require("fs");


//var joinLog = function (val) { console.log(val.join(""));};
//var log = function (val) { console.log(val);};

var vowels = ["a", "e", "i", "o", "u"];

var fsa = new FSA();
fsa.addPath(["m", "a", "t", "t"], 42);
fsa.addPath(["m", "a", "t", "t", "h", "e", "w"])
fsa.addPath("margin".split(""))
fsa.addPath([true, "i", "m"])
fsa.addPath(["d", "o", "n"])
fsa.addPath(["d", "a", "n"])
fsa.addPath(["f", true, "n"])
fsa.addPath([function (v) {return true}, "y", "a", "n"])
//var s1 = fsa.start;
//s1.connect(true, s1);

//fsa.graph("fsa.dot");

//fsa.print();

var testy = function (x) {
  assert.deepEqual(x.test("matt")[0], "matt".split(""));
  // Test final state value.
  assert.deepEqual(x.test("matt")[1], 42);
  assert.deepEqual(x.test("matthew")[0], "matthew".split(""));
  assert.deepEqual(x.test("mat"), false);
  assert.deepEqual(x.test("smatty"), false);
  assert.deepEqual(x.test("lim")[0], "lim".split(""));
  assert.deepEqual(x.test("dan")[0], "dan".split(""));

  assert.deepEqual(x.test("fan")[0], "fan".split(""));
  assert.deepEqual(x.test("fat"), false);
  //assert.deepEqual(x.test("fun"), true);
  assert.deepEqual(x.test("ryan")[0], "ryan".split(""));
}

testy(fsa);

var dump = fsa.dump();
var restored = FSA.load(dump);
//restored.graph("restored.dot");

testy(restored);

var str = fs.readFileSync("curfsa.json");
var restored = FSA.load(JSON.parse(str));
restored.graph("curfsa.dot");



