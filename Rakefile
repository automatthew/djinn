require "starter/tasks/npm"
require "starter/tasks/git"
require "starter/tasks/github"

task "build" do
	sh "coffee --compile --bare --output build/ src/"
end

desc "run tests"
task "test" => %w[test:fsa test:digraph]

task "test:fsa" do
  sh "coffee test/crappy_test.coffee"
end

task "test:digraph" do
  sh "coffee test/digraph.coffee"
end

task "test:digraph:dot" => "test:digraph" do
  sh "dot -Tpng inter.dot > inter.png"
end

task "dot" do
  files = FileList["**/*.dot"]
  files.each do |file|
    outfile = file.sub(/\.dot$/, ".png")
    sh "dot -Tpng #{file} > #{outfile}"
  end
end
