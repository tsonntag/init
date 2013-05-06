module Init
  class Application

    attr_reader :progname, :pid_dir, :periodic, :multi

    def initialize opts = {}
      @progname = opts[:progname] || File.basename($0)
      @pid_dir  = opts[:pid_dir]  || ENV['HOME'] || '/var/run'
      @periodic = opts[:periodic]
      @multi    = opts[:multi]
      raise "pid_dir #{@pid_dir} is not writable" unless File.writable?(@pid_dir)
    end

    # to be overwritten
    def call *args
    end

    # to be overwritten
    def stop
    end

    def command! *args
      if (command = args.last.to_s) =~ /\Astop|status\Z/  
        instances = args.size == 2 ? parse_instances(args[0]) : running_instances
        puts "no instances running for #{progname}" if instances.empty?
        instances.each{|instance| instance.send command.intern}
      elsif multi  && (command = args[1].to_s) =~ /\Arun|start\Z/
        parse_instances(args[0]).each{|instance|instance.send command.intern}
      elsif !multi && (command = args[0].to_s) =~ /\Arun|start\Z/
        Instance.new(self).send command.intern
      else
        usage
      end
    end

    private
    def running_instance_names
      pid_files.map{|pid_file| File.basename(pid_file).match(/(#{progname}.*)\.pid\Z/).captures.first}
    end

    def running_instances
      running_instance_names.map{|name|Instance.new(self,name)}
    end 
  
    def usage
      s = multi ? "#{progname} [<n>|<n>-<m>]" : progname
      STDERR.puts %Q( Usage: #{s} start | stop | run | status)
    end

    def pid_files
      Dir["#{pid_dir}/#{instance_name('*')}.pid"]
    end
   
    def instance_name n
      multi ? "#{progname}-#{n}" : progname
    end

    def parse_instances arg
      arg.split(/,/).map do |s|
        range = s.split(/-/)
        range.size == 2 ? (range.first..range.last).to_a : range
      end.uniq.flatten.map{|n| Instance.new self, instance_name(n)}
    end
  end

  class Instance
    attr_reader :progname, :pid_file, :app

    def initialize app, progname = nil
      @app = app
      @progname = progname || app.progname
      @pid_file = File.join(app.pid_dir,"#{@progname}.pid")
    end

    def stop_requested?
      @stop_requested
    end

    # run as daemon
    def start *args
      if daemon_running?
        STDERR.puts "Daemon #{progname} is already running with pid #{read_pid}"
      else
        fork do 
          Process.daemon
          save_pid 
          run *args
        end
      end
    end

    # stop daemon
    def stop 
      if pid = read_pid 
        Process.kill :INT, pid
      else
        STDERR.puts "No pid file #{pid_file}"
        exit 1
      end
    rescue Errno::ESRCH
      STDERR.puts "No daemon #{progname} running with pid #{read_pid}"
      exit 3
    ensure
      remove_pid 
    end
 
    def status
      if daemon_running? 
        puts "#{progname} running with pid #{read_pid}"
      else
        puts "#{progname} not running"
      end
    end

    # trap signals and call #call 
    def run *args
      @stop_requested = false

      %w(INT TERM).each do |s|
        trap(s) do
          logger.info{ "#{self}: signal caught. setting stop..." } if respond_to?(:logger)
          @stop_requested = true
          app.stop if app.respond_to?(:stop)
          remove_pid *args
        end
      end

      while !stop_requested?
        app.call *args
        break unless app.periodic

        logger.debug{"#{self}: sleeping #{app.periodic} seconds"} if respond_to?(:logger)
        app.periodic.times do
          break if stop_requested?
          sleep 1
        end
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
