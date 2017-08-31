require 'active_support'
require 'active_support/core_ext/module'

module Init
  module Stoppable

    def self.included(base)
      base.send :alias_method_chain, :stop, :stoppable
    end

    def stop_with_stoppable
      @stop_requested = true
      stop_without_stoppable
    end

    def stop_requested?
      @stop_requested
    end

    def trap_signals
      trap("INT"){signal}
      trap("KILL"){signal}
      trap("TERM"){signal}
    end

    def reset_stop
      @stop_requested = false
    end

    private
    def signal
      logger.info{ "#{self}: signal caught. setting stop..." } if logger
      stop
    end

  end
end
