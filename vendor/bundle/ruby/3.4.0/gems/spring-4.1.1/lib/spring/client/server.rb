module Spring
  module Client
    class Server < Command
      def self.description
        "Explicitly start a Spring server in the foreground"
      end

      def call
        require "spring/server"
        Spring::Server.boot(foreground: foreground?)
      end

      def foreground?
        !args.include?("--background")
      end
    end
  end
end
