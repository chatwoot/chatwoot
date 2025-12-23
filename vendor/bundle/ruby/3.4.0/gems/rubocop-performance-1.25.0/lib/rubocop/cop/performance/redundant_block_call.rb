# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies the use of a `&block` parameter and `block.call`
      # where `yield` would do just as well.
      #
      # @example
      #   # bad
      #   def method(&block)
      #     block.call
      #   end
      #   def another(&func)
      #     func.call 1, 2, 3
      #   end
      #
      #   # good
      #   def method
      #     yield
      #   end
      #   def another
      #     yield 1, 2, 3
      #   end
      class RedundantBlockCall < Base
        extend AutoCorrector

        MSG = 'Use `yield` instead of `%<argname>s.call`.'
        YIELD = 'yield'
        OPEN_PAREN = '('
        CLOSE_PAREN = ')'
        SPACE = ' '

        def_node_matcher :blockarg_def, <<~PATTERN
          {(def  _   (args ... (blockarg $_)) $_)
           (defs _ _ (args ... (blockarg $_)) $_)}
        PATTERN

        def_node_search :blockarg_calls, <<~PATTERN
          (send (lvar %1) :call ...)
        PATTERN

        def_node_search :blockarg_assigned?, <<~PATTERN
          (lvasgn %1 ...)
        PATTERN

        def on_def(node)
          blockarg_def(node) do |argname, body|
            next unless body

            calls_to_report(argname, body).each do |blockcall|
              next if blockcall.block_literal?

              add_offense(blockcall, message: format(MSG, argname: argname)) do |corrector|
                autocorrect(corrector, blockcall)
              end
            end
          end
        end
        alias on_defs on_def

        private

        # offenses are registered on the `block.call` nodes
        def autocorrect(corrector, node)
          _receiver, _method, *args = *node
          new_source = String.new(YIELD)
          unless args.empty?
            new_source += if parentheses?(node)
                            OPEN_PAREN
                          else
                            SPACE
                          end

            new_source << args.map(&:source).join(', ')
          end

          new_source << CLOSE_PAREN if parentheses?(node) && !args.empty?

          corrector.replace(node, new_source)
        end

        def calls_to_report(argname, body)
          return [] if blockarg_assigned?(body, argname) || shadowed_block_argument?(body, argname)

          blockarg_calls(body, argname).map do |call|
            return [] if args_include_block_pass?(call)

            call
          end
        end

        def shadowed_block_argument?(body, block_argument_of_method_signature)
          return false unless body.block_type?

          body.arguments.map(&:source).include?(block_argument_of_method_signature.to_s)
        end

        def args_include_block_pass?(blockcall)
          _receiver, _call, *args = *blockcall

          args.any?(&:block_pass_type?)
        end
      end
    end
  end
end
