begin
  require "starter/tasks/npm"
  require "starter/tasks/git"
  require "starter/tasks/github"
rescue LoadError => e
  warn "Missing Starter gem: relevant tasks will not be available"
end

task "build" do
	sh "coffee --compile --bare --output build/ src/"
end

desc "run tests"
task "test" => %w[ test:fsa test:digraph ]

task "test:fsa" do
  sh "coffee test/fsa_test.coffee"
end

task "test:digraph" do
  sh "coffee test/digraph_intersection.coffee"
end

rule ".png" => ".dot" do |t|
  sh "dot -Tpng #{t.source} > #{t.name}"
end

FileList["**/*.dot"].map do |file|
  name = file.sub(".dot", ".png")
  task "pngs" => name
end

