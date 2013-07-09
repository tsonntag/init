module Init
  # Usage example:
  #
  # Init::Server.create( some_uri ) do |server|
  #    server.add 'my_first_proc' do |args|
  #       puts 'first: called with #{args}'
  #    end
  #
  #    server.add 'my_second_proc', do |args|
  #       puts 'second: called with #{args}'
  #    end
  #
  # end
  class Server < Application
    include Init
    include DRbUndumped
    self.multi = false
    self.periodic = nil

    attr_reader :uri

    def initialize host, port
      @uri = "druby://#{host}:#{port}"
      super
    end

    def call *args
      self.send *args unless args.empty?
      DRb.start_service uri, self
      logger.info{"#{self} server started"}
      DRb.thread.join
    end

    def to_s
      "#{super}(#{uri})"
    end

    def item_class
      ThreadItem
    end

    def self.create *args
      server = new *args
      yield server
      server
    end

    def stop
      logger.info{"exiting... stopping all jobs"}
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

  end
end
