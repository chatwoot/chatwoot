# frozen_string_literal: true

require 'pg_search/migration/generator'

module PgSearch
  module Migration
    class MultisearchGenerator < Generator
      def migration_name
        'create_pg_search_documents'
      end
    end
  end
end
