require 'logger'

module Init
  # Usage example:
  #
  # Init::Server.create( some_logger, some_uri ) do |server|
  #    server.add 'my_first_proc' do |args|
  #       puts 'first: called with #{args}'
  #    end
  #
  #    server.add 'my_second_proc', do |args|
  #       puts 'second: called with #{args}'
  #    end
  #
  # end
  class AbstractServer < Init
    include DRbUndumped

    attr_reader :uri

    def initialize( host, port, logger = nil)
      @uri = "druby://#{host}:#{port}"
      super logger
    end

    def start_service( *args )
      trap("INT"){signal}
      trap("KILL"){signal}
      trap("TERM"){signal}
      self.send *args unless args.empty?
      DRb.start_service uri, self
      logger.info{"#{self} server started"}
      DRb.thread.join
    end

    def to_s
      "#{self.class}(#{uri})"
    end

    def self.create( host, port, logger = nil )
      server = new host, port, logger
      yield server
      server
    end

    def halt
      logger.info{"exiting... stopping all jobs"}
      stop
      wait_for_items_to_stop
      logger.info{"halted"}
      DRb.thread.exit
    end

    def wait_for_items_to_stop
      while not (alive = items_alive).empty?
        sleep 2
        logger.info{"exiting... waiting for jobs #{alive.map(&:name).join(',')} to stop"}
      end
    end

    private
    def signal
      logger.info{"#{self} caught signal. calling halt"}
      halt
    end

  end
end
