# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ColumnAnnotation
      class AnnotationBuilder
        def initialize(column, model, max_size, options)
          @column = column
          @model = model
          @max_size = max_size
          @options = options
        end

        def build
          column_attributes = @model.built_attributes[@column.name]
          formatted_column_type = TypeBuilder.new(@column, @options, @model.column_defaults).build

          display_column_comments = @options[:with_comment] && @options[:with_column_comments]
          display_column_comments &&= @model.with_comments? && @column.comment
          position_of_column_comment = @options[:position_of_column_comment] || Options::FLAG_OPTIONS[:position_of_column_comment] if display_column_comments

          max_attributes_size = @model.built_attributes.values.map { |v| v.join(", ").length }.max

          _component = ColumnComponent.new(
            column: @column,
            max_name_size: @max_size,
            type: formatted_column_type,
            attributes: column_attributes,
            position_of_column_comment: position_of_column_comment,
            max_attributes_size: max_attributes_size
          )
        end
      end
    end
  end
end
