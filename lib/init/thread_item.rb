require_relative 'abstract_item'

module Init
  class ThreadItem < AbstractItem
    attr_reader :thread

    def alive?
      !!(@thread.try :alive?)
    end

    def scheduled?
      @thread
    end

    def item_status
      if @thread
        case @thread.status
        when nil then 'exception'
        when false then 'exited'
        else @thread.status
        end
      else
        ''
      end
    end

    def do_stop
      @thread.wakeup
      proc.stop if proc.respond_to? :stop
    end

    private
    def do_start *args 
      @thread = Thread.new do
        logger.debug{"child: thread created. "}
        call *args
        @stop_requested = false
        @thread = nil
        logger.info{"stopped"}
      end
      @thread[:name] = name
    end
  end
end
