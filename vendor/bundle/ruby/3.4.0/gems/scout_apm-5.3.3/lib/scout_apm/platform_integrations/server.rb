# Classic hosting where you rent a server, then put your app on it.
# Used as fallback

module ScoutApm
  module PlatformIntegrations
    class Server
      def present?
        true
      end

      def name
        "Server"
      end

      def log_to_stdout?
        false
      end

      def hostname
        Socket.gethostname
      end
    end
  end
end
