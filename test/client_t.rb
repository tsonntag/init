$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'init'

Init::Client.new('localhost',4711).console('>> ')