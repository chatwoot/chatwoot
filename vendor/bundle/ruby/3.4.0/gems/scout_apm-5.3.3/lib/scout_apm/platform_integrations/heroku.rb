module ScoutApm
  module PlatformIntegrations
    class Heroku
      def present?
        !! ENV['DYNO']
      end

      def name
        "Heroku"
      end

      def log_to_stdout?
        true
      end

      def hostname
        ENV['DYNO']
      end
    end
  end
end
