require 'active_support/core_ext/class/attribute'
require 'active_support/inflector/methods'

module Init
  class Application

    class_attribute :progname, :pid_dir, :periodic, :multi

    self.progname = self.class.to_s.underscore
    self.pid_dir  = ENV['HOME'] || '/var/run'
    self.multi    = false
    self.periodic = nil

    # to be overwritten
    def call *args
    end

    # to be overwritten
    def stop
    end

    class << self
      def command! *args
        if (command = args.last.to_s) =~ /\Astop|status\Z/  
          instances = args.size == 2 ? parse_instances(args[0]) : running_instances
          puts "no instances running for #{progname}" if instances.empty?
        elsif  multi && (command = args[1].to_s) =~ /\Arun|start\Z/
          instances = parse_instances args[0]
        elsif !multi && (command = args[0].to_s) =~ /\Arun|start\Z/
          instances = [progname]
        else
          return usage
        end
        instances.each{|name| new(name).send command.intern}
      end

      private
      def running_instances
        pid_files.map{|pid_file| File.basename(pid_file).match(/(#{progname}.*)\.pid\Z/).captures.first}
      end

      def usage
        s = multi ? "#{progname} [<n>|<n>-<m>]" : progname
        STDERR.puts %Q( Usage: #{s} start | stop | run | status)
      end
  
      def pid_files
        validate_pid_dir
        Dir["#{pid_dir}/#{instance_name('*')}.pid"]
      end
     
      def instance_name n
        multi ? "#{progname}-#{n}" : progname
      end
  
      def parse_instances arg
        arg.split(/,/).map do |s|
          range = s.split(/-/)
          range.size == 2 ? (range.first..range.last).to_a : range
        end.uniq.flatten
      end

      def validate_pid_dir
        raise "pid_dir #{pid_dir} is not writable" unless File.writable?(pid_dir)
      end
    end


    def stop_requested?
      @stop_requested
    end

    def to_s
      @name
    end

    private

    def initialize name = progname
      @name = name
      self.class.validate_pid_dir
      @pid_file = File.join(self.class.pid_dir,"#{@name}.pid")
    end

    # run as daemon
    def start *args
      if daemon_running?
        STDERR.puts "Daemon #{@name} is already running with pid #{read_pid}"
      else
        fork do 
          Process.daemon
          save_pid 
          run *args
        end
      end
    end

    def stop 
      if pid = read_pid 
        Process.kill :INT, pid
      else
        STDERR.puts "No pid file #{pid_file}"
        exit 1
      end
    rescue Errno::ESRCH
      STDERR.puts "No daemon #{@name} running with pid #{read_pid}"
      exit 3
    ensure
      remove_pid 
    end
 
    def status
      if daemon_running? 
        puts "#{@name} running with pid #{read_pid}"
      else
        puts "#{@name} not running"
      end
    end

    # trap signals and call #call 
    def run *args
      @stop_requested = false

      %w(INT TERM).each do |s|
        trap(s) do
          logger.info{ "#{self}: signal caught. setting stop..." } if respond_to?(:logger)
          @stop_requested = true
          stop if respond_to?(:stop)
          remove_pid *args
        end
      end

      configure if respond_to?(:configure)

      while !stop_requested?
        call *args
        break unless periodic

        logger.debug{"#{self}: sleeping #{periodic} seconds"} if respond_to?(:logger)
        periodic.times do
          break if stop_requested?
          sleep 1
        end
      end

    end

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
