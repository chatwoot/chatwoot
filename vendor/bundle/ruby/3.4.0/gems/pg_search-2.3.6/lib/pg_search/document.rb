# frozen_string_literal: true

require 'logger'

module PgSearch
  class Document < ActiveRecord::Base
    include PgSearch::Model

    self.table_name = 'pg_search_documents'
    belongs_to :searchable, polymorphic: true

    # The logger might not have loaded yet.
    # https://github.com/Casecommons/pg_search/issues/26
    def self.logger
      super || Logger.new($stderr)
    end

    pg_search_scope :search, lambda { |*args|
      options = if PgSearch.multisearch_options.respond_to?(:call)
                  PgSearch.multisearch_options.call(*args)
                else
                  { query: args.first }.merge(PgSearch.multisearch_options)
                end

      { against: :content }.merge(options)
    }
  end
end
