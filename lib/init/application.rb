require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'
require_relative 'stoppable'

module Init
  class Application
    class_attribute :progname, :pid_dir

    def self.inherited base
      base.progname = base.name.to_s.underscore.split(/\//).last
    end

    self.pid_dir  = ENV['HOME'] || '/var/run'

    # to be overwritten
    def call *args
      @proc.call
    end

    include Stoppable

    def to_s
      progname
    end

    def initialize name = self.class.progname, &proc
      self.progname = name
      @proc = proc
      raise "pid_dir #{pid_dir} is not writable" unless File.writable?(pid_dir)
      @pid_file = File.join pid_dir,"#{progname}.pid"
    end

    # run as daemon
    def start! *args
      if daemon_running?
        STDERR.puts "Daemon #{progname} is already running with pid #{read_pid}"
      else
        logger.info{ "starting..." } if respond_to?(:logger)
        fork do 
          Process.daemon
          save_pid 
          run! *args
        end
      end
    end

    def stop! 
      if pid = read_pid 
        Process.kill :INT, pid
      else
        STDERR.puts "No pid file #{@pid_file}"
        exit 1
      end
    rescue Errno::ESRCH
      STDERR.puts "No daemon #{progname} running with pid #{read_pid}"
      exit 3
    end
 
    def status!
      if daemon_running? 
        puts "#{progname} running with pid #{read_pid}"
      else
        puts "#{progname} not running"
      end
    end

    # trap signals and call #call 
    def run! *args
      configure if respond_to?(:configure)

      Thread.current[:name] = progname

      %w(INT TERM).each do |s|
        trap(s) do
          logger.info{ "signal caught. setting stop..." } if respond_to?(:logger)
          stop!
        end
      end

      call *args

      remove_pid 
      logger.info{ "stopped." } if respond_to?(:logger)
    end

    def save_pid
      IO.write @pid_file, Process.pid.to_s
    end

    def remove_pid
      File.delete(@pid_file) if File.exists?(@pid_file)
    end

    def read_pid
      File.exists?(@pid_file) && File.read(@pid_file).strip.to_i
    end

    def daemon_running?
      pid = read_pid or return false
      Process.kill 0, pid
      true 
    rescue Errno::ESRCH 
      false
    end

  end
end
