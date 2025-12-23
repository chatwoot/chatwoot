# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ColumnAnnotation
      class TypeBuilder
        # Don't show limit (#) on these column types
        # Example: show "integer" instead of "integer(4)"
        NO_LIMIT_COL_TYPES = %w[integer bigint boolean].freeze

        def initialize(column, options, column_defaults)
          # Passing `column_defaults` for posterity, don't actually need it here since it's not used
          @column = ColumnWrapper.new(column, column_defaults, options)
          @options = options
        end

        # Returns the formatted column type as a string.
        def build
          column_type = @column.column_type_string

          formatted_column_type = column_type

          is_special_type = %w[spatial geometry geography].include?(column_type)
          is_decimal_type = column_type == "decimal"

          if is_decimal_type
            formatted_column_type = "decimal(#{@column.precision}, #{@column.scale})"
          elsif @options[:show_virtual_columns] && @column.virtual?
            formatted_column_type = "virtual(#{column_type})"
          elsif is_special_type
            # Do nothing. Kept as a code fragment in case we need to do something here.
          elsif @column.limit && !@options[:format_yard]
            # Unsure if Column#limit will ever be an array. May be safe to remove.
            if !@column.limit.is_a?(Array) && !hide_limit?
              formatted_column_type = column_type + "(#{@column.limit})"
            end
          end

          formatted_column_type
        end

        private

        def hide_limit?
          excludes =
            if @options[:hide_limit_column_types].blank?
              NO_LIMIT_COL_TYPES
            else
              @options[:hide_limit_column_types].split(",")
            end

          excludes.include?(@column.column_type_string)
        end
      end
    end
  end
end
