# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/keys"

module PgSearch
  module Features
    class Feature
      def self.valid_options
        %i[only sort_only]
      end

      delegate :connection, :quoted_table_name, to: :@model

      def initialize(query, options, all_columns, model, normalizer)
        @query = query
        @options = (options || {}).assert_valid_keys(self.class.valid_options)
        @all_columns = all_columns
        @model = model
        @normalizer = normalizer
      end

      private

      attr_reader :query, :options, :all_columns, :model, :normalizer

      def document
        columns.map(&:to_sql).join(" || ' ' || ")
      end

      def columns
        if options[:only]
          all_columns.select do |column|
            Array.wrap(options[:only]).map(&:to_s).include? column.name
          end
        else
          all_columns
        end
      end

      def normalize(expression)
        normalizer.add_normalization(expression)
      end
    end
  end
end
