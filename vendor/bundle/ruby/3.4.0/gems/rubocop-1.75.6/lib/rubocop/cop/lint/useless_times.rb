# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for uses of `Integer#times` that will never yield
      # (when the integer ``<= 0``) or that will only ever yield once
      # (`1.times`).
      #
      # @safety
      #   This cop is unsafe as `times` returns its receiver, which is
      #   *usually* OK, but might change behavior.
      #
      # @example
      #   # bad
      #   -5.times { do_something }
      #   0.times { do_something }
      #   1.times { do_something  }
      #   1.times { |i| do_something(i) }
      #
      #   # good
      #   do_something
      #   do_something(1)
      class UselessTimes < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Useless call to `%<count>i.times` detected.'
        RESTRICT_ON_SEND = %i[times].freeze

        # @!method times_call?(node)
        def_node_matcher :times_call?, <<~PATTERN
          (send (int $_) :times (block-pass (sym $_))?)
        PATTERN

        # @!method block_arg(node)
        def_node_matcher :block_arg, <<~PATTERN
          (block _ (args (arg $_)) ...)
        PATTERN

        # @!method block_reassigns_arg?(node)
        def_node_search :block_reassigns_arg?, <<~PATTERN
          (lvasgn %)
        PATTERN

        def on_send(node)
          return unless (count, proc_name = times_call?(node))
          return if count > 1

          # Get the block node if applicable
          node = node.block_node if node.block_literal?

          add_offense(node, message: format(MSG, count: count)) do |corrector|
            next if !own_line?(node) || node.parent&.send_type?

            autocorrect(corrector, count, node, proc_name)
          end
        end

        private

        def autocorrect(corrector, count, node, proc_name)
          if never_process?(count, node)
            remove_node(corrector, node)
          elsif !proc_name.empty?
            autocorrect_block_pass(corrector, node, proc_name)
          elsif node.block_type?
            autocorrect_block(corrector, node)
          end
        end

        def never_process?(count, node)
          count < 1 || (node.block_type? && node.body.nil?)
        end

        def remove_node(corrector, node)
          corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))
        end

        def autocorrect_block_pass(corrector, node, proc_name)
          corrector.replace(node, proc_name)
        end

        def autocorrect_block(corrector, node)
          block_arg = block_arg(node)
          return if block_reassigns_arg?(node, block_arg)

          source = node.body.source
          source.gsub!(/\b#{block_arg}\b/, '0') if block_arg

          corrector.replace(node, fix_indentation(source, node.loc.column...node.body.loc.column))
        end

        def fix_indentation(source, range)
          # Cleanup indentation in a multiline block
          source_lines = source.split("\n")

          source_lines[1..].each do |line|
            next if line.empty?

            line[range] = ''
          end
          source_lines.join("\n")
        end

        def own_line?(node)
          # If there is anything else on the line other than whitespace,
          # don't try to autocorrect
          processed_source.buffer.source_line(node.loc.line)[0...node.loc.column] !~ /\S/
        end
      end
    end
  end
end
