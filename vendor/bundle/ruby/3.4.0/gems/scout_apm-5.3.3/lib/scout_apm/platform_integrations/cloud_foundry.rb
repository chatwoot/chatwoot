module ScoutApm
  module PlatformIntegrations
    class CloudFoundry
      def present?
        !! ENV['VCAP_APPLICATION']
      end

      def name
        "Cloud Foundry"
      end

      # TODO: Which is easier for users by defualt? STDOUT or our log/scout_apm.log file?
      def log_to_stdout?
        true
      end

      # TODO: Is there a better way to get a hostname from Cloud Foundry?
      def hostname
        Socket.gethostname
      end
    end
  end
end
