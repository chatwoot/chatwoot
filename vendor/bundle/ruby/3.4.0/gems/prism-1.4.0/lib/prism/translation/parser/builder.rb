# frozen_string_literal: true

module Prism
  module Translation
    class Parser
      # A builder that knows how to convert more modern Ruby syntax
      # into whitequark/parser gem's syntax tree.
      class Builder < ::Parser::Builders::Default
        # It represents the `it` block argument, which is not yet implemented in the Parser gem.
        def itarg
          n(:itarg, [:it], nil)
        end

        # The following three lines have been added to support the `it` block parameter syntax in the source code below.
        #
        #   if args.type == :itarg
        #     block_type = :itblock
        #     args = :it
        #
        # https://github.com/whitequark/parser/blob/v3.3.7.1/lib/parser/builders/default.rb#L1122-L1155
        def block(method_call, begin_t, args, body, end_t)
          _receiver, _selector, *call_args = *method_call

          if method_call.type == :yield
            diagnostic :error, :block_given_to_yield, nil, method_call.loc.keyword, [loc(begin_t)]
          end

          last_arg = call_args.last
          if last_arg && (last_arg.type == :block_pass || last_arg.type == :forwarded_args)
            diagnostic :error, :block_and_blockarg, nil, last_arg.loc.expression, [loc(begin_t)]
          end

          if args.type == :itarg
            block_type = :itblock
            args = :it
          elsif args.type == :numargs
            block_type = :numblock
            args = args.children[0]
          else
            block_type = :block
          end

          if [:send, :csend, :index, :super, :zsuper, :lambda].include?(method_call.type)
            n(block_type, [ method_call, args, body ],
              block_map(method_call.loc.expression, begin_t, end_t))
          else
            # Code like "return foo 1 do end" is reduced in a weird sequence.
            # Here, method_call is actually (return).
            actual_send, = *method_call
            block =
              n(block_type, [ actual_send, args, body ],
                block_map(actual_send.loc.expression, begin_t, end_t))

            n(method_call.type, [ block ],
              method_call.loc.with_expression(join_exprs(method_call, block)))
          end
        end
      end
    end
  end
end
