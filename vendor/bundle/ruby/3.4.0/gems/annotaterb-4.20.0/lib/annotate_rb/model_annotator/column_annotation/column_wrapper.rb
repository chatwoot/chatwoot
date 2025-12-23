# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ColumnAnnotation
      class ColumnWrapper
        def initialize(column, column_defaults, options)
          @column = column
          @column_defaults = column_defaults
          @options = options
        end

        def raw_default
          @column.default
        end

        def default_value
          @column_defaults[@column.name]
        end

        def default_string
          quote(default_value)
        end

        def type
          @column.type
        end

        def column_type_string
          if (@column.respond_to?(:bigint?) && @column.bigint?) || /\Abigint\b/ =~ @column.sql_type
            "bigint"
          else
            (@column.type || @column.sql_type).to_s
          end
        end

        def unsigned?
          @column.respond_to?(:unsigned?) && @column.unsigned?
        end

        def null
          @column.null
        end

        def precision
          @column.precision
        end

        def scale
          @column.scale
        end

        def limit
          @column.limit
        end

        def geometry_type?
          @column.respond_to?(:geometry_type)
        end

        def geometry_type
          # TODO: Check if we need to check if it responds before accessing the geometry type
          @column.geometry_type
        end

        def geometric_type?
          @column.respond_to?(:geometric_type)
        end

        def geometric_type
          # TODO: Check if we need to check if it responds before accessing the geometric type
          @column.geometric_type
        end

        def srid
          # TODO: Check if we need to check if it responds before accessing the srid
          @column.srid
        end

        def array?
          @column.respond_to?(:array) && @column.array
        end

        def name
          @column.name
        end

        def virtual?
          @column.respond_to?(:virtual?) && @column.virtual?
        end

        def default_function
          @column.default_function
        end

        private

        # Simple quoting for the default column value
        def quote(value)
          DefaultValueBuilder.new(value, @options).build
        end
      end
    end
  end
end
