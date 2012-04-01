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
var state_list = fsa.add_path("margin")
fsa.add_arc(state_list[2], state_list[1], "z")

fsa.add_path("did")
var state_list = fsa.add_path("don")
var first = fsa.start;
var last = state_list[state_list.length - 1];
fsa.add_path("dad", null, {from: first, to: last})
fsa.add_path("ar".split(''), null, {from: state_list[1], to: state_list[2]})


fsa.write_graph("fsa.dot");

//fsa.print_att();

var testy = function (x) {
  assert(x.accept("matt"));
  assert(x.accept("matthew"));
  assert(x.accept("mazatthew"));
  assert(x.accept("mazazatthew"));
  assert(x.accept("mazazazatthew"));
  assert(x.accept("dad"));

  assert(!x.accept("mat"));
  assert(!x.accept("mazzatthew"));
  assert(!x.accept("smatty"));
  assert(!x.accept("daddyo"));
  assert(!x.accept("fat"));
  assert(!x.accept("do"));

  assert.deepEqual(x.match("matt").final_state.value, 42);
}

testy(fsa);

var dump = fsa.dump();
var restored = FSA.load(dump);
//restored.write_graph("restored.dot");

testy(restored);

var str = fs.readFileSync("./test/curfsa.json");
var restored = FSA.load(JSON.parse(str));
//restored.graph("./test/curfsa.dot");

//var connectives = new FSA()
//var words = fs.readFileSync("/usr/share/dict/connectives");
//words.toString().split("\n").forEach(function (word) {
  //if (word) {
    //connectives.add_path(word);
  //}
//});

//var all = new FSA()
//var words = fs.readFileSync("/usr/share/dict/words");
//words.toString().split("\n").forEach(function (word) {
  //if (word) {
    //all.add_path(word);
  //}
//});


//var inter = all.intersect(connectives);
//all.write_graph("fsa.dot");



