# frozen_string_literal: true

module RuboCop
  module Cop
    # A mixin to extend cops in order to determine the database type.
    #
    # This module automatically detect an adapter from `development` environment
    # in `config/database.yml` or the environment variable `DATABASE_URL`
    # when the `Database` option is not set.
    module DatabaseTypeResolvable
      MYSQL = 'mysql'
      POSTGRESQL = 'postgresql'

      def database
        cop_config['Database'] || database_from_yaml || database_from_env
      end

      private

      def database_from_yaml
        return unless database_yaml

        case database_adapter
        when 'mysql2', 'trilogy'
          MYSQL
        when 'postgresql', 'postgis'
          POSTGRESQL
        end
      end

      def database_from_env
        url = ENV.fetch('DATABASE_URL', '')
        return if url.blank?

        case url
        when %r{\A(mysql2|trilogy)://}
          MYSQL
        when %r{\Apostgres(ql)?://}
          POSTGRESQL
        end
      end

      def database_yaml
        return unless File.exist?('config/database.yml')

        yaml = if YAML.respond_to?(:unsafe_load_file)
                 YAML.unsafe_load_file('config/database.yml')
               else
                 YAML.load_file('config/database.yml')
               end
        return unless yaml.is_a? Hash

        config = yaml['development']
        return unless config.is_a?(Hash)

        config
      rescue Psych::SyntaxError
        # noop
      end

      def database_adapter
        database_yaml['adapter'] || database_yaml.first.last['adapter']
      end
    end
  end
end
