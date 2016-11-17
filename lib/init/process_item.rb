module Init

  class ProcessItem < AbstractItem
    
    attr_reader :child_pid

    def alive?
      child_pid && File.exists?("/proc/#{child_pid}")
    end

    def item_status
      alive? ? "alive" : ''
    end

    def child?
      !child_pid
    end

    def do_stop( *args ) # args without meaning
      logger.debug{"about to TERM #{name}, pid=#{child_pid}"}
      Process.kill('TERM', child_pid)
      #Process.wait(child_pid,Process::WNOHANG)
    rescue SystemCallError => e
      logger.error{"stopping #{name}, pid=#{child_pid} failed: #{e}"}
    end

    def to_s
      "%6s #{super}" % (child? ? Process.pid : 'parent')
    end

    private
    def do_start(*args)
      if (@child_pid = Process.fork)
        # parent
        #logger.debug{"parent: forked child #{@child_pid}"}
        Process.detach(@child_pid)
      else
        # child
        Thread.current[:progname] = name
        trap("TERM") do
          logger.debug{"child(#{Process.pid}): setting stop_requested = true"}
          @stop_requested = true
          proc.stop if proc.respond_to? :stop
        end
        call *args
        @stop_requested = false
        logger.info{"exit child(#{Process.pid})"}
        exit(0)
      end
    end

  end
  
end
