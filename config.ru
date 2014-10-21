#require './sqlite'
require './default'
#log = File.new("sinatra.log", "a+")
#$stdout.reopen(log)
#$stderr.reopen(log)
run MyApp.new
