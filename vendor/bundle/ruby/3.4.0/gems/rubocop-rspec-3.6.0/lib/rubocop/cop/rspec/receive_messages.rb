# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for multiple messages stubbed on the same object.
      #
      # @safety
      #   The autocorrection is marked as unsafe, because it may change the
      #   order of stubs. This in turn may cause e.g. variables to be called
      #   before they are defined.
      #
      # @example
      #   # bad
      #   before do
      #     allow(Service).to receive(:foo).and_return(bar)
      #     allow(Service).to receive(:baz).and_return(qux)
      #   end
      #
      #   # good
      #   before do
      #     allow(Service).to receive_messages(foo: bar, baz: qux)
      #   end
      #
      #   # good - ignore same message
      #   before do
      #     allow(Service).to receive(:foo).and_return(bar)
      #     allow(Service).to receive(:foo).and_return(qux)
      #   end
      #
      class ReceiveMessages < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `receive_messages` instead of multiple stubs on lines ' \
              '%<loc>s.'

        # @!method allow_receive_message?(node)
        def_node_matcher :allow_receive_message?, <<~PATTERN
          (send (send nil? :allow ...) :to (send (send nil? :receive (sym _)) :and_return !#heredoc_or_splat?))
        PATTERN

        # @!method allow_argument(node)
        def_node_matcher :allow_argument, <<~PATTERN
          (send (send nil? :allow $_ ...) ...)
        PATTERN

        # @!method receive_node(node)
        def_node_search :receive_node, <<~PATTERN
          $(send (send nil? :receive ...) ...)
        PATTERN

        # @!method receive_arg(node)
        def_node_search :receive_arg, <<~PATTERN
          (send (send nil? :receive $_) ...)
        PATTERN

        # @!method receive_and_return_argument(node)
        def_node_matcher :receive_and_return_argument, <<~PATTERN
          (send (send nil? :allow ...) :to (send (send nil? :receive (sym $_)) :and_return $_))
        PATTERN

        def on_begin(node)
          repeated_receive_message(node).each do |item, repeated_lines, args|
            next if repeated_lines.empty?

            register_offense(item, repeated_lines, args)
          end
        end

        private

        def repeated_receive_message(node)
          node
            .children
            .select { |child| allow_receive_message?(child) }
            .group_by { |child| allow_argument(child) }
            .values
            .reject(&:one?)
            .flat_map { |items| add_repeated_lines_and_arguments(items) }
        end

        def add_repeated_lines_and_arguments(items)
          uniq_items = uniq_items(items)
          repeated_lines = uniq_items.map(&:first_line)
          uniq_items.map do |item|
            [item, repeated_lines - [item.first_line], arguments(uniq_items)]
          end
        end

        def uniq_items(items)
          items.select do |item|
            items.none? do |i|
              receive_arg(item).first == receive_arg(i).first &&
                !same_line?(item, i)
            end
          end
        end

        def arguments(items)
          items.map do |item|
            receive_and_return_argument(item) do |receive_arg, return_arg|
              "#{normalize_receive_arg(receive_arg)}: " \
                "#{normalize_return_arg(return_arg)}"
            end
          end
        end

        def normalize_receive_arg(receive_arg)
          if requires_quotes?(receive_arg)
            "'#{receive_arg}'"
          else
            receive_arg
          end
        end

        def normalize_return_arg(return_arg)
          if return_arg.hash_type? && !return_arg.braces?
            "{ #{return_arg.source} }"
          else
            return_arg.source
          end
        end

        def register_offense(item, repeated_lines, args)
          add_offense(item, message: message(repeated_lines)) do |corrector|
            if item.loc.line > repeated_lines.max
              replace_to_receive_messages(corrector, item, args)
            else
              corrector.remove(item_range_by_whole_lines(item))
            end
          end
        end

        def message(repeated_lines)
          format(MSG, loc: repeated_lines)
        end

        def replace_to_receive_messages(corrector, item, args)
          receive_node(item) do |node|
            corrector.replace(node,
                              "receive_messages(#{args.join(', ')})")
          end
        end

        def item_range_by_whole_lines(item)
          range_by_whole_lines(item.source_range, include_final_newline: true)
        end

        def heredoc_or_splat?(node)
          (node.type?(:str, :dstr) && node.heredoc?) || node.splat_type?
        end

        def requires_quotes?(value)
          value.match?(/^:".*?"|=$|^\W+$/)
        end
      end
    end
  end
end
