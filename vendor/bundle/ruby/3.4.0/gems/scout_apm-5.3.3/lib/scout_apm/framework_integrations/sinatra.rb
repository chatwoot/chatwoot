module ScoutApm
  module FrameworkIntegrations
    class Sinatra
      def name
        :sinatra
      end

      def human_name
        "Sinatra"
      end

      def version
        ::Sinatra::VERSION
      end

      def present?
        defined?(::Sinatra) && defined?(::Sinatra::Base)
      end

      def application_name
        possible = ObjectSpace.each_object(Class).select { |klass| klass < ::Sinatra::Base } - [::Sinatra::Application]
        if possible.length == 1
          possible.first.name
        else
          "Sinatra"
        end
      rescue => e
        ScoutApm::Agent.instance.context.logger.debug "Failed getting Sinatra Application Name: #{e.message}\n#{e.backtrace.join("\n\t")}"
        "Sinatra"
      end

      def env
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      end

      # TODO: Figure out how to detect this smarter
      def database_engine
        :mysql
      end

      def raw_database_adapter
        :mysql
      end
    end
  end
end
