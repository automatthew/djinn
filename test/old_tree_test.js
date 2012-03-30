var vows = require("vows");
var assert = require("assert");
//var Runner = require("domRun").Runner;

var Tree = require("../build/old_tree");
var createNode = Tree.createNode;
var copyArrayTree = Tree.copyArrayTree;
var arrayNode = Tree.arrayNode;

//var runner = new Runner();
//runner.http.proxy = "http://127.0.0.1:9000/";

vows.describe("Tree traversal").addBatch({
  "an array-based tree" : {
    "topic" : function () {
      var tree = arrayNode.create(null, 1);
      var a = arrayNode.create(tree, 2);
      var b = arrayNode.create(tree, 3);
      var c = arrayNode.create(a, 4);
      return tree;
    },
    "can be traversed" : function (root) {
      var tree = copyArrayTree(root);
      assert.deepEqual(tree, [1, [
          [ 2, [[ 4 ]] ],
          [ 3 ]
        ]
      ]);
      Tree.traverse(root, function (node) { node[0] += 3; return node[1] || []} );
      assert.notDeepEqual(tree, root);
    }
  },
  //"a DOM" : {
    //"topic" : function () {
     //runner.request("http://en.wikipedia.org/wiki/Monkey_Shines", this.callback); 
    //},
    //"strip" : function (resource) {
      //var doc = resource.window.document;
      //var strip = Tree.stripDOM(doc);
      //var util = require("util");
      ////console.log(JSON.stringify(strip));
      //require("fs").writeFileSync("sparse.json", JSON.stringify(strip));
      ////console.log(util.inspect(strip, false, 25));
      //console.log(doc.innerHTML.length);
      //console.log(JSON.stringify(strip).length);
    //}
  //}
}).run()

