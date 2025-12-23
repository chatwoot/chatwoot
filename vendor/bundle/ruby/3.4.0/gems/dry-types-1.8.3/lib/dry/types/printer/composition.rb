# frozen_string_literal: true

module Dry
  module Types
    # @api private
    class Printer
      # @api private
      class Composition
        def initialize(printer, composition_class)
          @printer = printer
          @composition_class = composition_class
          freeze
        end

        def visit(composition)
          visit_constructors(composition) do |constructors|
            @printer.visit_options(composition.options, composition.meta) do |opts|
              yield "#{@composition_class.composition_name}<#{constructors}#{opts}>"
            end
          end
        end

        private

        def visit_constructors(composition)
          visit_constructor(composition.left) do |left|
            visit_constructor(composition.right) do |right|
              yield "#{left} #{@composition_class.operator} #{right}"
            end
          end
        end

        def visit_constructor(type, &)
          case type
          when @composition_class
            visit_constructors(type, &)
          else
            @printer.visit(type, &)
          end
        end
      end
    end
  end
end
