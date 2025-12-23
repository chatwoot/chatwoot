module ScoutApm
  module Tasks
    class Support
      def self.run!
        puts "Support Task"
        new.run!
      end

      def initialize
        @doctor = ScoutApm::Tasks::Doctor.new
      end

      def run!
        instruments = @doctor.installed_instruments
        config = @doctor.configuration_settings
        collect_logs

        post_data
      end
    end
  end
end
