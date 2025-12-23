module ScoutApm
  module FrameworkIntegrations
    class Rails2
      def name
        :rails
      end

      def human_name
        "Rails"
      end

      def version
        Rails::VERSION::STRING
      end

      def present?
        defined?(::Rails) &&
          defined?(::Rails::VERSION) &&
            defined?(ActionController) &&
          Rails::VERSION::MAJOR < 3
      end

      def application_name
        if defined?(::Rails)
          ::Rails.application.class.to_s.
            sub(/::Application$/, '')
        end
      rescue
        nil
      end

      def env
        RAILS_ENV.dup
      end

      # Attempts to determine the database engine being used
      def database_engine
        default = :mysql

        if defined?(ActiveRecord::Base)
          case raw_database_adapter
          when "postgres"   then :postgres
          when "postgresql" then :postgres
          when "postgis"    then :postgres
          when "sqlite3"    then :sqlite
          when "mysql"      then :mysql
          when "mysql2"     then :mysql
          else default
          end
        else
          default
        end
      rescue
        default
      end

      def raw_database_adapter
        ActiveRecord::Base.configurations[env]["adapter"]
      rescue
        nil
      end
    end
  end
end
