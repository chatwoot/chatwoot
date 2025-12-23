# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module CheckConstraintAnnotation
      class CheckConstraintComponent < Components::Base
        attr_reader :name, :expression, :max_size

        def initialize(name, expression, max_size)
          @name = name
          @expression = expression
          @max_size = max_size
        end

        def to_default
          # standard:disable Lint/FormatParameterMismatch
          sprintf("#  %-#{max_size}.#{max_size}s %s", name, expression).rstrip
          # standard:enable Lint/FormatParameterMismatch
        end

        def to_markdown
          if expression
            sprintf("# * `%s`: `%s`", name, expression)
          else
            sprintf("# * `%s`", name)
          end
        end
      end
    end
  end
end
