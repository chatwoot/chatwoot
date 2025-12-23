# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where custom code finding the sum of elements
      # in some Enumerable object can be replaced by `Enumerable#sum` method.
      #
      # @safety
      #   Autocorrections are unproblematic wherever an initial value is provided explicitly:
      #
      #   [source,ruby]
      #   ----
      #   [1, 2, 3].reduce(4, :+) # => 10
      #   [1, 2, 3].sum(4) # => 10
      #
      #   [].reduce(4, :+) # => 4
      #   [].sum(4) # => 4
      #   ----
      #
      #   This also holds true for non-numeric types which implement a `:+` method:
      #
      #   [source,ruby]
      #   ----
      #   ['l', 'o'].reduce('Hel', :+) # => "Hello"
      #   ['l', 'o'].sum('Hel') # => "Hello"
      #   ----
      #
      #   When no initial value is provided though, `Enumerable#reduce` will pick the first enumerated value
      #   as initial value and successively add all following values to it, whereas
      #   `Enumerable#sum` will set an initial value of `0` (`Integer`) which can lead to a `TypeError`:
      #
      #   [source,ruby]
      #   ----
      #   [].reduce(:+) # => nil
      #   [1, 2, 3].reduce(:+) # => 6
      #   ['H', 'e', 'l', 'l', 'o'].reduce(:+) # => "Hello"
      #
      #   [].sum # => 0
      #   [1, 2, 3].sum # => 6
      #   ['H', 'e', 'l', 'l', 'o'].sum # => in `+': String can't be coerced into Integer (TypeError)
      #   ----
      #
      # @example OnlySumOrWithInitialValue: false (default)
      #   # bad
      #   [1, 2, 3].inject(:+)                        # Autocorrections for cases without initial value are unsafe
      #   [1, 2, 3].inject(&:+)                       # and will only be performed when using the `-A` option.
      #   [1, 2, 3].reduce { |acc, elem| acc + elem } # They can be prohibited completely using `SafeAutoCorrect: true`.
      #   [1, 2, 3].reduce(10, :+)
      #   [1, 2, 3].map { |elem| elem ** 2 }.sum
      #   [1, 2, 3].collect(&:count).sum(10)
      #
      #   # good
      #   [1, 2, 3].sum
      #   [1, 2, 3].sum(10)
      #   [1, 2, 3].sum { |elem| elem ** 2 }
      #   [1, 2, 3].sum(10, &:count)
      #
      # @example OnlySumOrWithInitialValue: true
      #   # bad
      #   [1, 2, 3].reduce(10, :+)
      #   [1, 2, 3].map { |elem| elem ** 2 }.sum
      #   [1, 2, 3].collect(&:count).sum(10)
      #
      #   # good
      #   [1, 2, 3].sum(10)
      #   [1, 2, 3].sum { |elem| elem ** 2 }
      #   [1, 2, 3].sum(10, &:count)
      #
      class Sum < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.4

        MSG = 'Use `%<good_method>s` instead of `%<bad_method>s`.'
        MSG_IF_NO_INIT_VALUE =
          'Use `%<good_method>s` instead of `%<bad_method>s`, unless calling `%<bad_method>s` on an empty array.'
        RESTRICT_ON_SEND = %i[inject reduce sum].freeze

        def_node_matcher :sum_candidate?, <<~PATTERN
          (call _ ${:inject :reduce} $_init ? ${(sym :+) (block_pass (sym :+))})
        PATTERN

        def_node_matcher :sum_map_candidate?, <<~PATTERN
          (call
            {
              (block $(call _ {:map :collect}) ...)
              $(call _ {:map :collect} (block_pass _))
            }
          :sum $_init ?)
        PATTERN

        def_node_matcher :sum_with_block_candidate?, <<~PATTERN
          (block
            $(call _ {:inject :reduce} $_init ?)
            (args (arg $_acc) (arg $_elem))
            $send)
        PATTERN

        def_node_matcher :acc_plus_elem?, <<~PATTERN
          (send (lvar %1) :+ (lvar %2))
        PATTERN
        alias elem_plus_acc? acc_plus_elem?

        def on_send(node)
          return if empty_array_literal?(node)

          handle_sum_candidate(node)
          handle_sum_map_candidate(node)
        end
        alias on_csend on_send

        def on_block(node)
          sum_with_block_candidate?(node) do |send, init, var_acc, var_elem, body|
            if acc_plus_elem?(body, var_acc, var_elem) || elem_plus_acc?(body, var_elem, var_acc)
              range = sum_block_range(send, node)
              message = build_block_message(send, init, var_acc, var_elem, body)

              add_offense(range, message: message) do |corrector|
                autocorrect(corrector, init, range)
              end
            end
          end
        end

        private

        def handle_sum_candidate(node)
          sum_candidate?(node) do |method, init, operation|
            next if cop_config['OnlySumOrWithInitialValue'] && init.empty?

            range = sum_method_range(node)
            message = build_method_message(node, method, init, operation)

            add_offense(range, message: message) do |corrector|
              autocorrect(corrector, init, range)
            end
          end
        end

        def handle_sum_map_candidate(node)
          sum_map_candidate?(node) do |map, init|
            next if node.block_literal? || node.block_argument?

            message = build_sum_map_message(map, init)

            add_offense(sum_map_range(map, node), message: message) do |corrector|
              autocorrect_sum_map(corrector, node, map, init)
            end
          end
        end

        def empty_array_literal?(node)
          receiver = node.children.first
          array_literal?(node) && receiver && receiver.children.empty?
        end

        def array_literal?(node)
          receiver = node.children.first
          receiver&.literal? && receiver.array_type?
        end

        def autocorrect(corrector, init, range)
          return if init.empty? && safe_autocorrect?

          replacement = build_good_method(init)

          corrector.replace(range, replacement)
        end

        def autocorrect_sum_map(corrector, sum, map, init)
          sum_range = method_call_with_args_range(sum)
          map_range = method_call_with_args_range(map)

          block_pass = map.last_argument if map.last_argument&.block_pass_type?
          replacement = build_good_method(init, block_pass)

          corrector.remove(sum_range)

          dot = map.loc.dot&.source || ''
          corrector.replace(map_range, "#{dot}#{replacement}")
        end

        def sum_method_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end

        def sum_map_range(map, sum)
          range_between(map.loc.selector.begin_pos, sum.source_range.end.end_pos)
        end

        def sum_block_range(send, node)
          range_between(send.loc.selector.begin_pos, node.loc.end.end_pos)
        end

        def build_method_message(node, method, init, operation)
          good_method = build_good_method(init)
          bad_method = build_method_bad_method(init, method, operation)
          msg = if init.empty? && !array_literal?(node)
                  MSG_IF_NO_INIT_VALUE
                else
                  MSG
                end
          format(msg, good_method: good_method, bad_method: bad_method)
        end

        def build_sum_map_message(send_node, init)
          sum_method = build_good_method(init)
          good_method = "#{sum_method} { ... }"
          dot = send_node.loc.dot&.source || '.'
          bad_method = "#{send_node.method_name} { ... }#{dot}#{sum_method}"
          format(MSG, good_method: good_method, bad_method: bad_method)
        end

        def build_block_message(send, init, var_acc, var_elem, body)
          good_method = build_good_method(init)
          bad_method = build_block_bad_method(send.method_name, init, var_acc, var_elem, body)
          format(MSG, good_method: good_method, bad_method: bad_method)
        end

        def build_good_method(init, block_pass = nil)
          good_method = 'sum'

          args = []
          unless init.empty?
            init = init.first
            args << init.source unless init.int_type? && init.value.zero?
          end
          args << block_pass.source if block_pass
          good_method += "(#{args.join(', ')})" unless args.empty?
          good_method
        end

        def build_method_bad_method(init, method, operation)
          bad_method = "#{method}("
          unless init.empty?
            init = init.first
            bad_method += "#{init.source}, "
          end
          bad_method += if operation.block_pass_type?
                          '&:+)'
                        else
                          ':+)'
                        end
          bad_method
        end

        def build_block_bad_method(method, init, var_acc, var_elem, body)
          bad_method = method.to_s

          unless init.empty?
            init = init.first
            bad_method += "(#{init.source})"
          end
          bad_method += " { |#{var_acc}, #{var_elem}| #{body.source} }"
          bad_method
        end

        def method_call_with_args_range(node)
          if (receiver = node.receiver)
            receiver.source_range.end.join(node.source_range.end)
          else
            node.source_range
          end
        end
      end
    end
  end
end
