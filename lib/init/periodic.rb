module Init
  class PeriodicError < StandardError; end
  class Periodic
    attr_reader :seconds, :delegate, :logger

    def initialize delegate, seconds
      @delegate, @seconds = delegate, seconds
      raise PeriodicError, "#{delegate} does not respond to call" unless delegate.respond_to? :call
      @logger = @delegate.logger
    end

    def stop
      delegate.stop if delegate.respond_to? :stop
    end

    include Stoppable

    def call *args
      reset_stop
      logger.info{"Running #{delegate} every #{seconds} seconds"} if logger
      trap("INT"){signal}
      #trap("KILL"){signal} not supported by ruby 2.7.*
      trap("TERM"){signal}
      while !stop_requested?
        delegate.call *args
        logger.debug{"#{self}: about to sleep #{seconds} seconds"} if logger
        seconds.times do
          sleep 1
          break if stop_requested?
        end
      end
      logger.info{"#{self}: stopped"} if logger
    end

    def to_s
      delegate.to_s
    end

    private

    def signal
      stop
    end
  end
end
