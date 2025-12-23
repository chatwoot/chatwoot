# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Makes sure that certain binary operator methods have their
      # sole  parameter named `other`.
      #
      # @example
      #
      #   # bad
      #   def +(amount); end
      #
      #   # good
      #   def +(other); end
      class BinaryOperatorParameterName < Base
        extend AutoCorrector

        MSG = 'When defining the `%<opr>s` operator, name its argument `other`.'

        OP_LIKE_METHODS = %i[eql? equal?].freeze
        EXCLUDED = %i[+@ -@ [] []= << === ` =~].freeze

        # @!method op_method_candidate?(node)
        def_node_matcher :op_method_candidate?, <<~PATTERN
          (def [#op_method? $_] (args $(arg [!:other !:_other])) _)
        PATTERN

        def on_def(node)
          op_method_candidate?(node) do |name, arg|
            add_offense(arg, message: format(MSG, opr: name)) do |corrector|
              corrector.replace(arg, 'other')
              node.each_descendant(:lvar, :lvasgn) do |lvar|
                lvar_location = lvar.loc.name
                next unless lvar_location.source == arg.source

                corrector.replace(lvar_location, 'other')
              end
            end
          end
        end

        private

        def op_method?(name)
          return false if EXCLUDED.include?(name)

          !/\A[[:word:]]/.match?(name) || OP_LIKE_METHODS.include?(name)
        end
      end
    end
  end
end
