require 'drb'

module Init
  module Items
    CMDS = %w(list ls halt help start stop run alive status)

    def items
      @items ||= {}
    end

    def list pattern = nil
      find_items(pattern).map(&:line).join("\n")
    end

    alias_method :ls, :list

    def help
      CMDS.join " "
    end

    def items_alive
      items.select &:alive?
    end

    alias_method :alive, :items_alive

    # returns items for pattern. returns all if pattern == nil
    def find_items pattern = nil
      items.values_at(*find_names(pattern))
    end

    def find_names pattern = nil
      pattern.nil? ? items.keys : items.keys.select{|k|k.to_s =~ /#{pattern}/}
    end

    alias_method :[], :find_names

    def add name, proc 
      raise ArgumentError, "duplicate entry #{name}" if items.has_key?(name)
      item = item_class.new name, proc
      items[name] = item
    end

    def start *args; do_items "started", :start, *args end
    def stop *args;  do_items "stopped", :stop,  *args end

    def status pattern = nil
      find_items(pattern).group_by(&:status).map do |key,value|
        "%-3d processes %-20s" % [ value.size, key ]
      end * "\n"
    end
    
    private
    def msg text, items
      "#{text} #{items.map(&:name) * ' '}"
    end

    def do_items text, method, *args
      pattern, *args = args
      items = find_items pattern
      items.each{|item| item.send method, *args}
      msg text, items
    end
  end
end
