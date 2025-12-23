# frozen_string_literal: true

module Judoscale
  class JobMetricsCollector
    module ActiveRecordHelper
      # Cleanup any whitespace characters (including new lines) from the SQL for simpler logging.
      # Reference: ActiveSupport's `squish!` method. https://api.rubyonrails.org/classes/String.html#method-i-squish
      def self.cleanse_sql(sql)
        sql = sql.dup
        sql.gsub!(/[[:space:]]+/, " ")
        sql.strip!
        sql
      end

      # This will respect a multiple-database setup, unlike the `table_exists?` method.
      def self.table_exists_for_model?(model)
        model.connection.schema_cache.data_source_exists?(model.table_name)
      rescue ActiveRecord::NoDatabaseError
        false
      end

      def self.table_exists?(table_name)
        ::ActiveRecord::Base.connection.table_exists?(table_name)
      rescue ActiveRecord::NoDatabaseError
        false
      end

      private

      def run_silently(&block)
        if Config.instance.log_level && ::ActiveRecord::Base.logger.respond_to?(:silence)
          ::ActiveRecord::Base.logger.silence(Config.instance.log_level) { yield }
        else
          yield
        end
      end

      def select_rows_silently(sql)
        run_silently { select_rows_tagged(sql) }
      end

      def select_rows_tagged(sql)
        if ActiveRecord::Base.logger.respond_to?(:tagged)
          ActiveRecord::Base.logger.tagged(Config.instance.log_tag) { select_rows(sql) }
        else
          select_rows(sql)
        end
      end

      def select_rows(sql)
        # This ensures the agent doesn't hold onto a DB connection any longer than necessary
        ActiveRecord::Base.connection_pool.with_connection { |c| c.select_rows(sql) }
      end
    end
  end
end
