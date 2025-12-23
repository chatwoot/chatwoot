module ScoutApm
  module FrameworkIntegrations
    class Rails3Or4
      def name
        :rails3_or_4
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
          Rails::VERSION::MAJOR >= 3
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
        ::Rails.env
      end

      def database_engine
        return @database_engine if @database_engine
        default = :postgres

        @database_engine = if defined?(ActiveRecord::Base)
          adapter = raw_database_adapter # can be nil

          case adapter.to_s
          when "postgres"   then :postgres
          when "postgresql" then :postgres
          when "postgis"    then :postgres
          when "sqlite3"    then :sqlite
          when "sqlite"     then :sqlite
          when "mysql"      then :mysql
          when "mysql2"     then :mysql
          when "sqlserver"  then :sqlserver
          else default
          end
        else
          # TODO: Figure out how to detect outside of Rails context. (sequel, ROM, etc)
          default
        end
      end

      # Note, this code intentionally avoids `.respond_to?` because of an
      # infinite loop created by the Textacular gem (tested against 3.2.2 of
      # that gem), which some customers have installed.
      #
      # The loop was:
      #   - Ask for database adapter
      #   - Do .respond_to? on AR::Base to look for connection_config (which isn't present on some versions of rails)
      #   - Textacular gem has a monkey-patch that queries the columns of the db
      #     This obtains a connection, and runs a query.
      #   - Scout tries to run SQLSanitizer against the query, which needs the database adapter.
      #   - Goes back to first step.
      #
      # We avoid this issue by not calling .respond_to? here, and instead using the less optimal `rescue nil` approach
      def raw_database_adapter
        adapter = ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] rescue nil

        if adapter.nil?
          adapter = ActiveRecord::Base.connection_config[:adapter].to_s rescue nil
        end

        if adapter.nil?
          adapter = ActiveRecord::Base.configurations.to_h[env]["adapter"]
        end

        return adapter
      rescue # this would throw an exception if ActiveRecord::Base is defined but no configuration exists.
        nil
      end
    end
  end
end
