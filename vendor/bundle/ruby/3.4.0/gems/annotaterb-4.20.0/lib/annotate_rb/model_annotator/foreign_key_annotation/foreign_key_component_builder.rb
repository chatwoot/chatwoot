# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ForeignKeyAnnotation
      class ForeignKeyComponentBuilder
        attr_reader :foreign_key

        def initialize(foreign_key, options)
          @foreign_key = foreign_key
          @options = options
        end

        def formatted_name
          @formatted_name ||= if foreign_key.name.blank?
            foreign_key.column
          else
            @options[:show_complete_foreign_keys] ? foreign_key.name : foreign_key.name.gsub(/(?<=^fk_rails_)[0-9a-f]{10}$/, "...")
          end
        end

        def stringified_columns
          @stringified_columns ||= stringify(foreign_key.column)
        end

        def stringified_primary_key
          @stringified_primary_key ||= stringify(foreign_key.primary_key)
        end

        def constraints_info
          @constraints_info ||= begin
            constraints_info = ""
            constraints_info += "ON DELETE => #{foreign_key.on_delete} " if foreign_key.on_delete
            constraints_info += "ON UPDATE => #{foreign_key.on_update} " if foreign_key.on_update
            constraints_info.strip
          end
        end

        def ref_info
          if foreign_key.column.is_a?(Array) # Composite foreign key using multiple columns
            "#{stringified_columns} => #{foreign_key.to_table}#{stringified_primary_key}"
          else
            "#{foreign_key.column} => #{foreign_key.to_table}.#{foreign_key.primary_key}"
          end
        end

        private

        # The fk columns or primary key might be composite (an Array), so format them into a string for the annotation
        def stringify(columns)
          columns.is_a?(Array) ? "[#{columns.join(", ")}]" : columns
        end
      end
    end
  end
end
