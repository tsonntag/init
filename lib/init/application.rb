module Init
  class Application

    attr_reader :progname, :pid_file

    def initialize progname = File.basename($0), pid_file = "/var/run/#{progname}.pid"
      @progname, @pid_file = progname, pid_file
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
        run! *args
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

    def run! *args
      @stop_requested = false

      %w(INT TERM).each do |s|
        trap(s) do
          logger.info{ "#{self}: signal caught. setting stop..." } if logger
          @stop_requested = true
          stop
          remove_pid
        end
      end

      call *args
    end

    def usage
      STDERR.puts %Q( Usage: #{File.basename($0)} start | stop | run | status)
    end

    def command args = ARGV
      cmd = args.shift
      case cmd 
      when /start|stop|run/
        send :"#{cmd}!"
      when 'status'
        status
      else
        usage 
      end
    end

    def to_s
      progname
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
