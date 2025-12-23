require 'yaml'

module DatabaseCleaner
  module Spec
    class DatabaseHelper < Struct.new(:db)
      def self.with_all_dbs &block
        %w[mysql2 sqlite3 postgres].map(&:to_sym).each do |db|
          yield new(db)
        end
      end

      def setup
        create_db
        establish_connection
        load_schema
      end

      attr_reader :connection

      def teardown
        drop_db
      end

      private

      def establish_connection(config = default_config)
        raise NotImplementedError
      end

      def create_db
        if db == :sqlite3
          # NO-OP
        elsif db == :postgres
          establish_connection default_config.merge('database' => 'postgres')
          connection.execute "CREATE DATABASE #{default_config['database']}" rescue nil
        else
          establish_connection default_config.merge("database" => nil)
          connection.execute "CREATE DATABASE IF NOT EXISTS #{default_config['database']}"
        end
      end

      def load_schema
        id_column = case db
          when :sqlite3
            "id INTEGER PRIMARY KEY AUTOINCREMENT"
          when :mysql2
            "id INTEGER PRIMARY KEY AUTO_INCREMENT"
          when :postgres
            "id SERIAL PRIMARY KEY"
          end
        connection.execute <<-SQL
          CREATE TABLE IF NOT EXISTS users (
            #{id_column},
            name INTEGER
          );
        SQL

        connection.execute <<-SQL
          CREATE TABLE IF NOT EXISTS agents (
            name INTEGER
          );
        SQL
      end

      def drop_db
        if db == :sqlite3
          begin
            File.unlink(db_config['sqlite3']['database'])
          rescue Errno::ENOENT
          end
        elsif db == :postgres
          # FIXME
          connection.execute "DROP TABLE IF EXISTS users"
          connection.execute "DROP TABLE IF EXISTS agents"
        else
          connection.execute "DROP DATABASE IF EXISTS #{default_config['database']}"
        end
      end

      def db_config
        config_path = 'spec/support/config.yml'
        @db_config ||= YAML.load(IO.read(config_path))
      end

      def default_config
        db_config[db.to_s]
      end
    end
  end
end
