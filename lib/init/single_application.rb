require_relative 'application'

module Init
  class SingleApplication < Application
    class << self
      def command! *args
        raise ArgumentError, "invalid argument #{args}" unless args.size == 1
        instance = new(progname)
        if instance.respond_to?(args.first) 
          instance.send :"#{args.first}!"
        else
          STDERR.puts %Q( Usage: #{progname} start | stop | run | status)
        end
      end
    end
  end
end
