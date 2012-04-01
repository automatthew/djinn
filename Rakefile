$COFFEE = "node_modules/coffee-script/bin/coffee"

task "build" do
	sh "#{$COFFEE} --compile --bare --output build/ src/"
end

task "test" => %w[test:fsa test:digraph]

task "test:fsa" => "build" do
  sh "node test/fsaTest.js"
end

task "test:digraph" => "build" do
  sh "coffee test/digraph.coffee"
end

task "test:digraph:dot" => "test:digraph" do
  sh "dot -Tpng inter.dot > inter.png"
end
