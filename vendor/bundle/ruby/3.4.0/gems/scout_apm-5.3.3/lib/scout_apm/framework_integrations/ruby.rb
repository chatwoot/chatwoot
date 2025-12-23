module ScoutApm
  module FrameworkIntegrations
    class Ruby
      def name
        :ruby
      end

      def human_name
        "Ruby"
      end

      def version
        "Unknown"
      end

      def present?
        true
      end

      # TODO: Fetch the name (Somehow?)
      def application_name
        "Ruby"
      end

      def env
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      end

      # TODO: Figure out how to accomodate odd environments
      def database_engine
        :mysql
      end

      def raw_database_adapter
        :mysql
      end
    end
  end
end
