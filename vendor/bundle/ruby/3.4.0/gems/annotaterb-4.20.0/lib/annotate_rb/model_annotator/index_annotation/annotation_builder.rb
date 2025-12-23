# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module IndexAnnotation
      class AnnotationBuilder
        def initialize(model, options)
          @model = model
          @options = options
        end

        def build
          return Components::NilComponent.new if !@options[:show_indexes]

          indexes = @model.retrieve_indexes_from_table
          return Components::NilComponent.new if indexes.empty?

          max_size = indexes.map { |index| index.name.size }.max + 1

          indexes = indexes.sort_by(&:name).map do |index|
            IndexComponent.new(index, max_size, @options)
          end

          _annotation = Annotation.new(indexes)
        end
      end
    end
  end
end
