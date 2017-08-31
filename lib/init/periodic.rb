module Init
  class PeriodicError < StandardError; end
  class Periodic
    attr_reader :seconds, :delegate

    def initialize( delegate, seconds )
      @delegate, @seconds = delegate, seconds
      raise PeriodicError, "delegate #{delegate} does not respond to call" unless delegate.respond_to? :call
    end

    def stop
      delegate.stop if delegate.respond_to? :stop
    end

    include Stoppable

    def call(*args)
      reset_stop
      logger.info{"#{self}: started with periodic=#{seconds}, args=#{args.inspect}"} if logger
      trap("INT"){signal}
      trap("KILL"){signal}
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
      "#{self.class}(#{delegate},#{seconds}secs)"
    end

    private

    def signal
      stop
    end

    def logger
      @logger ||= delegate.logger
    end

  end
end
