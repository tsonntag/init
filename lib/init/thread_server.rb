require 'drb'
require_relative 'items'
require_relative 'thread_item'
require_relative 'single_application'

module Init
  # Usage example:
  #
  # Init::ThreadServer.create( some_uri ) do |server|
  #    server.add 'my_first_proc' do |args|
  #       puts 'first: called with #{args}'
  #    end
  #
  #    server.add 'my_second_proc', do |args|
  #       puts 'second: called with #{args}'
  #    end
  #
  # end
  class Server < SingleApplication
    include Items
    include DRbUndumped

    def command! *args
      *names, command = args

      case command
      when 'status', 'stop'
        if running?
          target.send :"#{command}!"
        else
          puts "#{progname} server not running" 
        end
      when 'run', 'start'
        target.send :"#{command}!"
      else 
        usage
      end
    end

    attr_reader :uri

    def initialize host, port
      @host, @port = host, port
      @uri = "druby://#{host}:#{port}"
      super
    end

    def client
      @client ||= Client.new @host, post
    end

    def target
      running? ? client, self 
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

    def self.create *args
      server = new *args
      yield server
      server
    end

    private
    def stop
      logger.info{"exiting... stopping all jobs"}
      wait_for_items_to_stop
      logger.info{"halted"}
      DRb.thread.exit
    end

    def item_class
      ThreadItem
    end

    def wait_for_items_to_stop
      while not (alive = items_alive).empty?
        sleep 2
        logger.info{"exiting... waiting for jobs #{alive.map(&:name).join(',')} to stop"}
      end
    end

  end
end
