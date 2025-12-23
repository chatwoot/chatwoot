# frozen_string_literal: true

require 'active_record'
require 'rails/generators/base'

module PgSearch
  module Migration
    class Generator < Rails::Generators::Base
      Rails::Generators.hide_namespace namespace

      def self.inherited(subclass)
        super
        subclass.source_root File.expand_path('templates', __dir__)
      end

      def create_migration
        now = Time.now.utc
        filename = "#{now.strftime('%Y%m%d%H%M%S')}_#{migration_name}.rb"
        template "#{migration_name}.rb.erb", "db/migrate/#{filename}", migration_version
      end

      private

      def read_sql_file(filename)
        sql_directory = File.expand_path('../../../sql', __dir__)
        source_path = File.join(sql_directory, "#{filename}.sql")
        File.read(source_path).strip
      end

      def migration_version
        if ActiveRecord::VERSION::MAJOR >= 5
          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        else
          ""
        end
      end
    end
  end
end
