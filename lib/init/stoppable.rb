module Init
  module Stoppable

    def self.included base
      base.send :attr_accessor, :periodic
      base.class_eval do
        alias_method :call_without_stoppable, :call
        alias_method :call, :call_with_stoppable
      end
    end

    def stop_requested?
      @stop_requested
    end

    def stop!
      @stop_requested = true
      stop if respond_to? :stop
    end

    def call_with_stoppable *args
      @stop_requested = false

      while !stop_requested?
        call_without_stoppable *args
        break unless periodic

        logger.debug{"sleeping #{periodic} seconds"} if respond_to?(:logger)
        periodic.times do
          break if stop_requested?
          sleep 1
        end
      end
    end

  end
end
