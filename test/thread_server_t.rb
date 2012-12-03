$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'init'
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
Init::ThreadServer.create('localhost',4711,logger) do |server|
  server.add 'my_first_proc', 10, lambda{ |*args|
    puts "first: called with #{args}"
  }
  server.add 'my_second_proc', 8, lambda{ |*args|
    puts "seconf: called with #{args}"
  }
end.start_service
