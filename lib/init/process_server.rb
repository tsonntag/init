module Init
  class ProcessServer < AbstractServer

    protected

    def item_class
      ProcessItem
    end
    
    #def wait_for_items_to_stop
    #  #logger.debug{"#{self}: before Process.wait"}
    #  #Process.wait
    #  #logger.debug{"#{self}: after Process.wait"}
    #  super
    #rescue Errno::ECHILD => e
    #  logger.debug{"#{self}: wait: #{e.inspect}"}
    #end

  end

end
