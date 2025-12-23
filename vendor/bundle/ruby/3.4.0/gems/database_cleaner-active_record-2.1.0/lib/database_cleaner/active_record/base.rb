require 'active_record'
require 'database_cleaner/strategy'
require 'erb'
require 'yaml'

module DatabaseCleaner
  module ActiveRecord
    def self.config_file_location=(path)
      @config_file_location = path
    end

    def self.config_file_location
      @config_file_location ||= "#{Dir.pwd}/config/database.yml"
    end

    class Base < DatabaseCleaner::Strategy
      def self.migration_table_name
        if Gem::Version.new("6.0.0") <= ::ActiveRecord.version
          ::ActiveRecord::Base.connection.schema_migration.table_name
        else
          ::ActiveRecord::SchemaMigration.table_name
        end
      end

      def self.exclusion_condition(column_name)
        <<~SQL
          #{column_name} <> '#{DatabaseCleaner::ActiveRecord::Base.migration_table_name}'
            AND #{column_name} <> '#{::ActiveRecord::Base.internal_metadata_table_name}'
        SQL
      end

      def db=(*)
        super
        load_config
      end

      attr_accessor :connection_hash

      def connection_class
        @connection_class ||= if db && !db.is_a?(Symbol)
                                db
                              elsif connection_hash
                                (lookup_from_connection_pool rescue nil) || establish_connection
                              else
                                ::ActiveRecord::Base
                              end
      end

      private

      def load_config
        if db != :default && db.is_a?(Symbol) && File.file?(DatabaseCleaner::ActiveRecord.config_file_location)
          connection_details =
            if RUBY_VERSION.match?(/\A2\.5/)
              YAML.safe_load(ERB.new(IO.read(DatabaseCleaner::ActiveRecord.config_file_location)).result, [], [], true)
            else
              YAML.safe_load(ERB.new(IO.read(DatabaseCleaner::ActiveRecord.config_file_location)).result, aliases: true)
            end
          @connection_hash   = valid_config(connection_details, db.to_s)
        end
      end

      def valid_config(connection_file, db)
        return connection_file[db] unless (active_record_config_hash = active_record_config_hash_for(db))

        active_record_config_hash
      end

      def active_record_config_hash_for(db)
        if ::ActiveRecord.version >= Gem::Version.new('6.1')
          ::ActiveRecord::Base.configurations&.configs_for(name: db)&.configuration_hash
        else
          ::ActiveRecord::Base.configurations[db]
        end
      end

      def lookup_from_connection_pool
        return unless ::ActiveRecord::Base.respond_to?(:descendants)

        database_name = connection_hash['database'] || connection_hash[:database]
        ::ActiveRecord::Base.descendants.select(&:connection_pool).detect do |model|
          database_for(model) == database_name
        end
      end

      def establish_connection
        ::ActiveRecord::Base.establish_connection(connection_hash)
        ::ActiveRecord::Base
      end

      def database_for(model)
        if model.connection_pool.respond_to?(:db_config) # ActiveRecord >= 6.1
          model.connection_pool.db_config.configuration_hash[:database]
        else
          model.connection_pool.spec.config[:database]
        end
      end
    end
  end
end
