require 'rubygems'
require 'readline'
require 'drb'
require 'active_support/core_ext'

module Init
  class Client
    URI = "druby://localhost:8787"

    attr_reader :server, :uri

    # Usage example:
    #
    # Init::Client.new("druby://0.0.0.0:8788").console('processc> ')
    # starts console with prompt 'processc>'
    def initialize( host, port )
      DRb.start_service
      @uri = "druby://#{host}:#{port}"
      @server = DRbObject.new_with_uri(uri)
    end

    def method_missing(*args)
      server.send *args
    end

    def console( prompt = "#{server} >" )
      setup_readline
      while s = Readline.readline(prompt ,true)
        s.strip!
        break if s =~ /^q(uit)?$/
        next if s =~ /^\s*$/
        cmd, *args = s.split
        cmd = cmd.intern
        #puts "* s=#{s}, cmd=#{cmd}, args=#{args}"
        if server.respond_to? cmd
          puts begin
            args.blank? ? server.send(cmd) : server.send(cmd, *args)
          rescue => e
            "ERROR: #{e.inspect}. #{e.backtrace.join("\n")}"
          end
        else
          puts "ERROR: unknown command: #{cmd}"
        end
      end
    end

    private
    def setup_readline
      Readline.basic_word_break_characters= 7.chr # dummy unused character
      Readline.completion_append_character = " "
      Readline.completion_proc = proc do |s|
        cmd, arg = s.split
        #puts ">>s=#{s.inspect}, cmd=#{cmd.inspect}, arg=#{arg.inspect}<<"
        if Init::CMDS.include? cmd
          args = server.names.map &:to_s
          if arg.nil?
            args
          else
            args.grep /^#{Regexp.escape(arg)}/
          end.map{|arg| "#{cmd} #{arg}"}
        else
          Init::CMDS.grep(/^#{Regexp.escape(cmd||'')}/).map{|m|m+" "}
        end
      end
    end
  end
end
