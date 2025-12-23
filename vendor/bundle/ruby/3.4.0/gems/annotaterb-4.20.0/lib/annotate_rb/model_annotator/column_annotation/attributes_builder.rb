# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ColumnAnnotation
      class AttributesBuilder
        # Don't show default value for these column types
        NO_DEFAULT_COL_TYPES = %w[json jsonb hstore].freeze

        def initialize(column, options, is_primary_key, column_indices, column_defaults)
          @column = ColumnWrapper.new(column, column_defaults, options)
          @options = options
          @is_primary_key = is_primary_key
          @column_indices = column_indices
        end

        # Get the list of attributes that should be included in the annotation for
        # a given column.
        def build
          column_type = @column.column_type_string
          attrs = []

          if !@column.raw_default.nil? && !hide_default?
            schema_default = "default(#{@column.default_string})"

            attrs << schema_default
          end

          if @column.unsigned?
            attrs << "unsigned"
          end

          if !@column.null
            attrs << "not null"
          end

          if @is_primary_key
            attrs << "primary key"
          end

          is_special_type = %w[spatial geometry geography].include?(column_type)
          is_decimal_type = column_type == "decimal"

          if !is_decimal_type && !is_special_type
            if @column.limit && !@options[:format_yard]
              if @column.limit.is_a?(Array)
                attrs << "(#{@column.limit.join(", ")})"
              end
            end
          end

          # Check out if we got an array column
          if @column.array?
            attrs << "is an Array"
          end

          # Check out if we got a geometric column
          # and print the type and SRID
          if @column.geometry_type?
            attrs << "#{@column.geometry_type}, #{@column.srid}"
          elsif @column.geometric_type? && @column.geometric_type.present?
            attrs << "#{@column.geometric_type.to_s.downcase}, #{@column.srid}"
          end

          # Check if the column has indices and print "indexed" if true
          # If the index includes another column, print it too.
          if @options[:simple_indexes]
            # Note: there used to be a klass.table_exists? call here, but removed it as it seemed unnecessary.

            sorted_column_indices&.each do |index|
              indexed_columns = index.columns.reject { |i| i == @column.name }

              index_text = if index.unique
                "uniquely indexed"
              else
                "indexed"
              end

              attrs << if indexed_columns.empty?
                index_text
              else
                "#{index_text} => [#{indexed_columns.join(", ")}]"
              end
            end
          end

          # Check if the column is a virtual column and print the function
          if @options[:show_virtual_columns] && @column.virtual?
            # Any whitespace in the function gets reduced to a single space
            attrs << @column.default_function.gsub(/\s+/, " ").strip
          end

          attrs
        end

        def sorted_column_indices
          # Not sure why there were & safe accessors here, but keeping in for time being.
          sorted_indices = @column_indices&.sort_by(&:name)

          _sorted_indices = sorted_indices.reject { |ind| ind.columns.is_a?(String) }
        end

        # Historically, the old gem looked for the option being set to "skip"
        # e.g. hide_default_column_types: "skip"
        def hide_default?
          excludes =
            if @options[:hide_default_column_types].blank?
              NO_DEFAULT_COL_TYPES
            else
              @options[:hide_default_column_types].split(",")
            end

          excludes.include?(@column.column_type_string)
        end
      end
    end
  end
end
