require_relative 'application'

module Init
  class MultiApplication < Application

    class << self
      def command! *args
        *names, command = *args

        case command
        when 'stop', 'status'
          instances = names.empty? ? running_instances : parse_instances(names) 
          puts "no instances running for #{progname}" if instances.empty?
        when 'run', 'start'
          instances = parse_instances args.first
        else
          return usage
        end
        instances.each{|name| new(name).send :"#{command}!"}
      end

      private
      def running_instances
        pid_files.map{|pid_file| File.basename(pid_file).gsub(/\.pid\Z/,'')}
      end

      def usage
        STDERR.puts %Q( Usage: #{progname}  [<n>|<n>-<m>...] start | stop | run | status)
      end
  
      def pid_files
        raise "pid_dir #{pid_dir} is not writable" unless File.writable?(pid_dir)
        Dir["#{pid_dir}/#{instance_name('*')}.pid"]
      end
     
      def instance_name n
        "#{progname}-#{n}" 
      end
  
      def parse_instances *args
        args.map do |arg| 
          arg.split(/,/).map do |s|
            range = s.split(/-/)
            range.size == 2 ? (range.first..range.last).to_a : range
          end
        end.uniq.flatten.map{|n|instance_name n}
      end
    end

  end
end
