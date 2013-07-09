require 'drb'

module Init
  class AbstractItem
    include DRbUndumped
    attr_reader :name, :proc

    def initialize name, proc
      @name, @proc = name, proc
      @stop_requested = false
    end

    def stop_requested?
      @stop_requested
    end

    def status
      "#{item_status}#{stop_requested? ? ' stop requested' : ''}"
    end

    def start *args
      unless alive?
        @stop_requested = false
        logger.debug{"about to start #{name} args=#{args.inspect}"}
        do_start *args
        logger.info{"started #{name}. args=#{args.inspect}"}
      end
    end

    def stop *ignored 
      if alive?
        logger.debug{"#{self}: setting stop_requested = true"}
        @stop_requested = true
        do_stop 
      end
    end

    def call *args 
      logger.debug{"about to call #{name}, args=#{args.inspect}"}
      if args.empty?
        proc.call
      else
        proc.call *args
      end
      logger.debug{"called #{name}"}
    rescue Object => e
      logger.error{"#{name} failed: #{e}. proc= #{proc}. #{e.backtrace.join("\n")}"}
    end

    def to_s
      "#{name}:#{status}"
    end

    def line
      "%-20s - %s" % [ name, status ]
    end

  end

end
