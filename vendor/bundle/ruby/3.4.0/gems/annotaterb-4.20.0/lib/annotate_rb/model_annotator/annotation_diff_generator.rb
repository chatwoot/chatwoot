# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    # Compares the current file content and new annotation block and generates the column annotation differences
    class AnnotationDiffGenerator
      HEADER_PATTERN = /(^# Table name:.*?\n(#.*\r?\n)*\r?)/
      # Example matches:
      #   - "#  id              :uuid             not null, primary key"
      #   - "#  title(length 255) :string          not null"
      #   - "#  status(a/b/c)    :string           not null"
      #   - "#  created_at       :datetime         not null"
      #   - "#  updated_at       :datetime         not null"
      COLUMN_PATTERN = /^#[\t ]+[[\p{L}\p{N}_]*.`\[\]():]+(?:\(.*?\))?[\t ]+.+$/
      class << self
        def call(file_content, annotation_block)
          new(file_content, annotation_block).generate
        end
      end

      # @param [String] file_content The current file content of the model file we intend to annotate
      # @param [String] annotation_block The annotation block we intend to write to the model file
      def initialize(file_content, annotation_block)
        @file_content = file_content
        @annotation_block = annotation_block
      end

      def generate
        # Ignore the Schema version line because it changes with each migration
        current_annotations = @file_content.match(HEADER_PATTERN).to_s
        new_annotations = @annotation_block.match(HEADER_PATTERN).to_s

        current_annotation_columns = if current_annotations.present?
          current_annotations.scan(COLUMN_PATTERN).sort
        else
          []
        end

        new_annotation_columns = if new_annotations.present?
          new_annotations.scan(COLUMN_PATTERN).sort
        else
          []
        end

        _result = AnnotationDiff.new(current_annotation_columns, new_annotation_columns)
      end
    end
  end
end
