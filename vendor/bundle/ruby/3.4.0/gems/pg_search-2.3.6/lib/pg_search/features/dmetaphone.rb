# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

module PgSearch
  module Features
    class DMetaphone
      def initialize(query, options, columns, model, normalizer)
        dmetaphone_normalizer = Normalizer.new(normalizer)
        options = (options || {}).merge(dictionary: 'simple')
        @tsearch = TSearch.new(query, options, columns, model, dmetaphone_normalizer)
      end

      delegate :conditions, to: :tsearch

      delegate :rank, to: :tsearch

      private

      attr_reader :tsearch

      # Decorates a normalizer with dmetaphone processing.
      class Normalizer
        def initialize(normalizer_to_wrap)
          @normalizer_to_wrap = normalizer_to_wrap
        end

        def add_normalization(original_sql)
          otherwise_normalized_sql = Arel.sql(
            normalizer_to_wrap.add_normalization(original_sql)
          )

          Arel::Nodes::NamedFunction.new(
            "pg_search_dmetaphone",
            [otherwise_normalized_sql]
          ).to_sql
        end

        private

        attr_reader :normalizer_to_wrap
      end
    end
  end
end
