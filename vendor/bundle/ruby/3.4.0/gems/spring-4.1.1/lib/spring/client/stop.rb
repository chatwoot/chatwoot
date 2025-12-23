require "spring/version"

module Spring
  module Client
    class Stop < Command
      def self.description
        "Stop all Spring processes for this project."
      end

      def call
        case env.stop
        when :stopped
          puts "Spring stopped."
        when :killed
          $stderr.puts "Spring did not stop; killing forcibly."
        when :not_running
          puts "Spring is not running"
        end
      end
    end
  end
end
