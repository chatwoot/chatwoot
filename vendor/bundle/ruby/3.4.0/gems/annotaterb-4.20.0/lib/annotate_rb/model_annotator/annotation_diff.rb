# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    # Plain old Ruby object for holding the differences
    class AnnotationDiff
      attr_reader :current_columns, :new_columns

      def initialize(current_columns, new_columns)
        @current_columns = current_columns.dup.freeze
        @new_columns = new_columns.dup.freeze
      end

      def changed?
        @changed ||= @current_columns != @new_columns
      end
    end
  end
end
