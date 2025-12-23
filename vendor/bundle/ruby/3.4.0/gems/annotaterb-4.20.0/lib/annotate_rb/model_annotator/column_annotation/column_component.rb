# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ColumnAnnotation
      class ColumnComponent < Components::Base
        MD_TYPE_ALLOWANCE = 18
        BARE_TYPE_ALLOWANCE = 16
        MIN_SPACES_BEFORE_COMMENT = 4

        attr_reader :column, :max_name_size, :type, :attributes, :position_of_column_comment, :max_attributes_size

        def initialize(column:, max_name_size:, type:, attributes:, position_of_column_comment:, max_attributes_size:)
          @column = column
          @max_name_size = max_name_size
          @type = type
          @attributes = attributes
          @position_of_column_comment = position_of_column_comment
          @max_attributes_size = max_attributes_size
        end

        def name
          case position_of_column_comment
          when :with_name
            "#{column.name}(#{escaped_column_comment})"
          else
            column.name
          end
        end

        def escaped_column_comment
          column.comment.to_s.gsub(/\n/, '\\n')
        end

        def to_rdoc
          # standard:disable Lint/FormatParameterMismatch
          format("# %-#{max_name_size}.#{max_name_size}s<tt>%s</tt>",
            "*#{name}*::",
            attributes.unshift(type).join(", ")).rstrip
          # standard:enable Lint/FormatParameterMismatch
        end

        def to_yard
          res = ""
          res += sprintf("# @!attribute #{name}") + "\n"

          ruby_class = if @column.respond_to?(:array) && @column.array
            "Array<#{map_col_type_to_ruby_classes(type)}>"
          else
            map_col_type_to_ruby_classes(type)
          end

          res += sprintf("#   @return [#{ruby_class}]")

          res
        end

        def to_markdown
          joined_attributes = attributes.join(", ").rstrip
          name_remainder = max_name_size - name.length - non_ascii_length(name)
          type_remainder = (MD_TYPE_ALLOWANCE - 2) - type.length
          attributes_remainder = max_attributes_size + 1 - joined_attributes.length
          comment_rightmost = (position_of_column_comment != :rightmost_column) ? "" : " | `#{escaped_column_comment}`"

          # standard:disable Lint/FormatParameterMismatch
          format(
            "# **`%s`**%#{name_remainder}s | `%s`%#{type_remainder}s | `%s`%#{attributes_remainder}s", # %s",
            name,
            " ",
            type,
            " ",
            joined_attributes,
            comment_rightmost.to_s
          ).gsub("``", "  ").rstrip
          # standard:enable Lint/FormatParameterMismatch
        end

        def to_default
          comment_rightmost = (position_of_column_comment == :rightmost_column) ? escaped_column_comment : ""
          joined_attributes = attributes.join(", ")
          format(
            "#  %s:%s %s %s",
            mb_chars_ljust(name, max_name_size),
            mb_chars_ljust(type, BARE_TYPE_ALLOWANCE),
            mb_chars_ljust(joined_attributes, max_attributes_size.to_i + MIN_SPACES_BEFORE_COMMENT),
            comment_rightmost
          ).rstrip
        end

        private

        def mb_chars_ljust(string, length)
          string = string.to_s
          padding = length - Helper.width(string)
          if padding.positive?
            string + (" " * padding)
          else
            string[0..(length - 1)]
          end
        end

        def map_col_type_to_ruby_classes(col_type)
          case col_type
          when "integer" then Integer.to_s
          when "float" then Float.to_s
          when "decimal" then BigDecimal.to_s
          when "datetime", "timestamp", "time" then Time.to_s
          when "date" then Date.to_s
          when "text", "string", "binary", "inet", "uuid" then String.to_s
          when "json", "jsonb" then Hash.to_s
          when "boolean" then "Boolean"
          end
        end

        def non_ascii_length(string)
          string.to_s.chars.count { |element| !element.ascii_only? }
        end
      end
    end
  end
end
