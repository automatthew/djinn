var FSA = require('fsa').FSA;

var Storage = exports.Storage = function () {
  this.fsa = new FSA();
};

Storage.prototype.store = function (signature, val) {
  this.fsa.addPath(signature, val);
  return val;
};


Storage.prototype.retrieve = function (signature) {
  var match = this.fsa.test(signature);
  return match ? match[1] : false ;
};

//Storage.prototype.destroy = function (signature) {
  //var obj = this.data;
  //var step;
  //var stack = [];
  //var last;

  //for (var i=0,l=signature.length-1;i<l;i++) {
    //step = signature[i];
    //if (!obj[step]) { return }
    //stack.push([obj, step]);
    //obj = obj[step];
  //}
  //step = signature[i++];
  //var out = delete obj[step];

  //while (last = stack.pop()) {
    //if (isEmpty(last[0][last[1]])) {
      //delete last[0][last[1]];
    //} else {
      //return;
    //}
  //}
  //return out;
//};


Storage.prototype.list = function () {
  return this.fsa.finalStates().map(function (s) {
    return s.finalValue;
  });
};

Storage.prototype.dump = function () {
  return this.fsa.dump();
};

Storage.load = function (dump) {
  var s = new Storage();
  s.fsa = FSA.load(dump);
  return s;
};

//Old stuff

//Storage.prototype.list = function () {
  //return getList(this.data, [], []);
//};

var getList = function getList (obj, stack, out) {
  if (typeof(obj) === "object") {
    // keep traversing
    for (var prop in obj) {
      if (obj.hasOwnProperty(prop)) {
        stack.push(prop);
        getList(obj[prop], stack, out);
        stack.pop();
      }
    }
  } else {
    // leaf node
    out.push({value: obj, path: stack.slice(0)});
  }
  return out;
};

var isEmpty = function isEmpty(obj) {
  for(var prop in obj) {
    if(obj.hasOwnProperty(prop)) { return false; }
  }
  return true;
}



