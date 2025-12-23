# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ForeignKeyAnnotation
      class AnnotationBuilder
        def initialize(model, options)
          @model = model
          @options = options
        end

        def build
          return Components::NilComponent.new if !@options[:show_foreign_keys]
          return Components::NilComponent.new unless @model.connection.respond_to?(:supports_foreign_keys?) &&
            @model.connection.supports_foreign_keys? && @model.connection.respond_to?(:foreign_keys)

          foreign_keys = @model.connection.foreign_keys(@model.table_name)
          return Components::NilComponent.new if foreign_keys.empty?

          fks = foreign_keys.map do |fk|
            ForeignKeyComponentBuilder.new(fk, @options)
          end

          max_size = fks.map(&:formatted_name).map(&:size).max + 1

          foreign_key_components = fks.sort_by { |fk| [fk.formatted_name, fk.stringified_columns] }.map do |fk|
            # fk is a ForeignKeyComponentBuilder

            ForeignKeyComponent.new(fk.formatted_name, fk.constraints_info, fk.ref_info, max_size)
          end

          _annotation = Annotation.new(foreign_key_components)
        end
      end
    end
  end
end
