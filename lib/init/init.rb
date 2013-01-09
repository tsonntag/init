require 'logger'
require 'drb'
require 'rubygems'
require 'active_support/core_ext'

module Init
  CMDS = %w(list ls halt help start stop run alive status)

  class Init

    attr_reader :logger, :items

    def initialize( logger = nil )
      @logger = logger || begin
        l = Logger.new(STDOUT)
        l.level = Logger::DEBUG
        l.formatter = Logger::Formatter.new
        l
      end
      @items = {}
    end

    def list(pattern=nil)
      items(pattern).map(&:line).join("\n")
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
    def items(pattern=nil)
      @items.values_at(*names(pattern))
    end

    def names(pattern=nil)
      pattern.nil? ? @items.keys : @items.keys.select{|k|k.to_s =~ /#{pattern}/}
    end

    alias_method :[], :names

    def add(name, proc)
      raise ArgumentError, "duplicate entry #{name}" if @items.has_key?(name)
      item = item_class.new name, logger, proc
      @items[name] = item
    end

    def start(*args); do_items "started", :start, *args end
    def stop(*args);  do_items "stopped", :stop,  *args end

    def status(pattern=nil)
      items(pattern).group_by(&:status).map do |key,value|
        "%-3d processes %-20s" % [ value.size, key ]
      end * "\n"
    end
    
    private
    def msg(text, items)
      "#{text} #{items.map(&:name) * ' '}"
    end

    def do_items(text, method, *args)
      pattern, *args = args
      items = items pattern
      items.each{|item| item.send(method, *args)}
      msg text, items
    end
  end
end
