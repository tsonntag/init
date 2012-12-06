require 'active_support/core_ext/module/aliasing'

module Init
  module Stoppable

    def self.included base
      base.send :alias_method_chain, :stop, :stoppable
      base.send :alias_method_chain, :call, :stoppable
    end

    def stop_with_stoppable
      @stop_requested = true
      stop_without_stoppable
      remove_pid
    end

    def stop_requested?
      @stop_requested
    end

    def start! *args
      if daemon_running?
        STDERR.puts "Daemon is already running with pid #{read_pid}"
      else
        Process.daemon
        save_pid
        call *args
      end
    end

    def stop!
      if pid = read_pid
        Process.kill :INT, pid
      else
        STDERR.puts "No pid file #{pid_file}"
        exit 1
      end
    rescue Errno::ESRCH
      STDERR.puts "No daemon running with pid #{read_pid}"
      exit 3
    ensure
      remove_pid
    end

    def status
      if daemon_running?
        puts "running with pid #{read_pid}"
      else
        puts "not running"
      end
    end

    def call_with_stoppable *args
      @stop_requested = false

      %w(INT TERM).each do |s|
        trap(s) do
          logger.info{ "#{self}: signal caught. setting stop..." } if logger
          stop
        end
      end

      call_without_stoppable *args
    end

    def progname= progname
      @progname = progname
    end

    def progname
      @progname ||= File.basename($0)
    end

    def pid_file= pid_file
      @pid_file = pid_file
    end

    def pid_file
      @pid_file ||= "/var/run/#{progname}.pid"
    end

    private
    def save_pid
      IO.write pid_file, Process.pid.to_s
    end

    def remove_pid
      File.delete(pid_file) if File.exists?(pid_file)
    end

    def read_pid
      File.exists?(pid_file) && File.read(pid_file).strip.to_i
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
