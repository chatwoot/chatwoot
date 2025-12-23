module ScoutApm
  module Tasks
    class Doctor
      def self.run!
        new.run!
      end

      def initialize()
      end

      def run!
        puts "Scout Doctor"
        puts "============"
        puts
        puts "Detected App Server: #{agent_context.environment.app_server_integration.name}"
        # puts "Detected Background Job: #{agent_context.environment.background_job_integration.name}"
        puts
        puts "Instruments:"
        puts "----------------------------------------"
        puts installed_instruments
        puts
        puts
        puts "Configuration Settings:"
        puts "-------------|------------------------------|-------"
        puts "    From     |             Key              | Value "
        puts "-------------|------------------------------|-------"
        puts configuration_settings
        puts
        puts
        puts "Misc:"
        puts "---------------"
        puts "Layaway Files stored at: #{agent_context.layaway.directory}"
        puts "Logs stored at: #{log_details}"

      end

      def agent_context
        ScoutApm::Agent.instance.context
      end

      def installed_instruments
        ScoutApm::Agent.
          instance.
          instrument_manager.
          installed_instruments.
          map{|instance| "#{instance.installed? ? "Installed    " : "Not Installed"} - #{instance.class.to_s}"}.
          join("\n")
      end

      def configuration_settings
        all_settings = agent_context.config.all_settings

        longest_key = all_settings.
          map{|setting| setting[:key] }.
          inject(0) { |len, key| key.length > len ? key.length : len }

        format_string = "%12s | %-#{longest_key}s | %s"

        all_settings.
          map{|setting| sprintf format_string, setting[:source], setting[:key], setting[:value]}.
          join("\n")
      end

      def log_details
        if agent_context.logger.log_destination == STDOUT
          "STDOUT"
        elsif agent_context.logger.log_destination == STDERR
          "STDERR"
        else
          "#{agent_context.logger.log_file_path}"
        end
      end
    end
  end
end
