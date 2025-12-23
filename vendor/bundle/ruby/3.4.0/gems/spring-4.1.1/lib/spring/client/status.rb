module Spring
  module Client
    class Status < Command
      def self.description
        "Show current status."
      end

      def call
        if env.server_running?
          puts "Spring is running:"
          puts
          print_process env.pid
          application_pids.each { |pid| print_process pid }
        else
          puts "Spring is not running."
        end
      end

      def print_process(pid)
        puts `ps -p #{pid} -o pid= -o command=`
      end

      def application_pids
        candidates = `ps -ax -o ppid= -o pid=`.lines
        candidates.select { |l| l =~ /^(\s+)?#{env.pid} / }
                  .map    { |l| l.split(" ").last   }
      end
    end
  end
end
