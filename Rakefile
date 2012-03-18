$COFFEE = "node_modules/coffee-script/bin/coffee"

task "build" do
	sh "#{$COFFEE} --compile --bare --output build/ src/"
end

task "test" => "build" do
  sh "node test/fsaTest.js"
end
