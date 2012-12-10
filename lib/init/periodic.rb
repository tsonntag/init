module Init
  module Periodic

    def self.included base
      base.send :alias_method_chain, :call, :periodic
      base.send :attr_accessor, :seconds
    end

    def call_with_periodic *args
      logger.info{"#{self}: started with periodic=#{seconds}, args=#{args.inspect}"} if logger

      while !stop_requested?
        call_without_periodic *args
        logger.debug{"#{self}: sleeping #{seconds} seconds"} if logger
        break unless seconds
        seconds.times do
          sleep 1
          break if stop_requested?
        end
      end
      logger.info{"#{self}: stopped"} if logger
    end

  end
end
