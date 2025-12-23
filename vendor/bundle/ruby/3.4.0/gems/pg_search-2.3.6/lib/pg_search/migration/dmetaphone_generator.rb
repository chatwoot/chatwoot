# frozen_string_literal: true

require 'pg_search/migration/generator'

module PgSearch
  module Migration
    class DmetaphoneGenerator < Generator
      def migration_name
        'add_pg_search_dmetaphone_support_functions'
      end
    end
  end
end
