# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module CheckConstraintAnnotation
      class AnnotationBuilder
        def initialize(model, options)
          @model = model
          @options = options
        end

        def build
          return Components::NilComponent.new if !@options[:show_check_constraints]
          return Components::NilComponent.new unless @model.connection.respond_to?(:supports_check_constraints?) &&
            @model.connection.supports_check_constraints? && @model.connection.respond_to?(:check_constraints)

          check_constraints = @model.connection.check_constraints(@model.table_name)
          return Components::NilComponent.new if check_constraints.empty?

          max_size = check_constraints.map { |check_constraint| check_constraint.name.size }.max + 1

          constraints = check_constraints.sort_by(&:name).map do |check_constraint|
            expression = if check_constraint.expression
              if check_constraint.validated?
                "(#{check_constraint.expression.squish})"
              else
                "(#{check_constraint.expression.squish}) NOT VALID".squish
              end
            end

            CheckConstraintComponent.new(check_constraint.name, expression, max_size)
          end

          _annotation = Annotation.new(constraints)
        end
      end
    end
  end
end
