# Djinn:  Finite State Automata in Javascript

Inspirations:

* [OpenFST](http://www.openfst.org/twiki/bin/view/FST/WebHome)
* [Ken Thompson's NFA algorithm](http://swtch.com/~rsc/regexp/regexp1.html)

## Notes from various emails:


FSMs are effectively directed graphs (with a global source), so I
extracted everything possible into a directed graph class.

https://github.com/automatthew/djinn/blob/master/src/digraph.coffee

The FSA class extends Digraph.  It has `accept`, `match`, and
`matches` methods for testing input strings or arrays.  It's still
suffering from cruft, feature creep, and indecision.  The test script
shows you pretty much all the primitives it offers.

https://github.com/automatthew/djinn/blob/master/src/fsa.coffee
https://github.com/automatthew/djinn/blob/master/test/fsaTest.js

---

I had graphs on the brain this weekend, so I refurbished Djinn.

There's now a base Digraph class that requires you to implement
your own Vertex and Arc (a.k.a. node and edge) classes.  So far I supply
a NaiveDigraph subclass that's based on mindless OO patterns and a
SequenceAcceptor (currently using NaiveDigraph, but could use any other
Digraph class). The SequenceAcceptor is a limited FSM for matching
strings or arrays.

Aside from refurbishings, the really cool thing that happened was the
implementation of digraph-intersection.  In other words, Djinn can now
take two FSMs and generate an intersection of the grammars they
express.  String matching is a special case of FSA intersection where
the string is assumed to be a trivial FSA with each state having one
and only one transition to the next state.

Near Future Coolness:  the *intersection* algorithm for finite state
*acceptors* is apparently a special case of the *composition*
algorithm for finite state *transducers*.  That is, where an Acceptor
can only return matches from inputs, a Transducer can return
transformations.  FSTransducer composition is exactly analogous to
function or set composition.

Limitations:  I stepped waaaay back from my idea of allowing each FSA
transition to do arbitrary matching.  Doing anything other than exact
matching drops you straight into Cartesian Product territory.  That
territory may well be worth exploring for situations with known bounds
on the number of arcs per vertex (aka transitions leaving each state),
but I'm not assuming that constraint for now.  It should be
near-trivial to add later, by augmenting the way the Arc classes test
equivalence.

Interoperability:  AT&T's fsm and OpenFST emit and consume simple text
formats.  Djinn easily could be modified to emit/consume these
formats.  This means that a production environment could take FSMs
created in the browser by Djinn and perform complex, CPU intensive
operations with a highly-optimized OpenFST application.  Or a browser
could use Djinn to perform less intensive operations on an FSM
constructed and maintained by OpenFST.

TODOS:
* subclass of Digraph that uses an adjacency list for vertex/arc operations
* dump/load functions for OpenFST text format
* transducer subclass (both input and output values for each arc)
* regex compiler (mostly for demo)
* subclass that maintains a codebook of arc values, using integer labels
for the actual arc storage.

