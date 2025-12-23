# frozen_string_literal: true

require "pg_search/multisearch/rebuilder"

module PgSearch
  module Multisearch
    class << self
      def rebuild(model, deprecated_clean_up = nil, clean_up: true, transactional: true)
        unless deprecated_clean_up.nil?
          ActiveSupport::Deprecation.warn(
            "pg_search 3.0 will no longer accept a boolean second argument to PgSearchMultisearch.rebuild, " \
            "use keyword argument `clean_up:` instead."
          )
          clean_up = deprecated_clean_up
        end

        if transactional
          model.transaction { execute(model, clean_up) }
        else
          execute(model, clean_up)
        end
      end

      private

      def execute(model, clean_up)
        PgSearch::Document.where(searchable_type: model.base_class.name).delete_all if clean_up
        Rebuilder.new(model).rebuild
      end
    end

    class ModelNotMultisearchable < StandardError
      def initialize(model_class)
        super
        @model_class = model_class
      end

      def message
        "#{@model_class.name} is not multisearchable. See PgSearch::ClassMethods#multisearchable"
      end
    end
  end
end
