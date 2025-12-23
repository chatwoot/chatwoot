# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for multiple `defined?` calls joined by `&&` that can be combined
      # into a single `defined?`.
      #
      # When checking that a nested constant or chained method is defined, it is
      # not necessary to check each ancestor or component of the chain.
      #
      # @example
      #   # bad
      #   defined?(Foo) && defined?(Foo::Bar) && defined?(Foo::Bar::Baz)
      #
      #   # good
      #   defined?(Foo::Bar::Baz)
      #
      #   # bad
      #   defined?(foo) && defined?(foo.bar) && defined?(foo.bar.baz)
      #
      #   # good
      #   defined?(foo.bar.baz)
      class CombinableDefined < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Combine nested `defined?` calls.'
        OPERATORS = %w[&& and].freeze

        def on_and(node)
          # Only register an offense if all `&&` terms are `defined?` calls
          return unless (terms = terms(node)).all?(&:defined_type?)

          calls = defined_calls(terms)
          namespaces = namespaces(calls)

          calls.each do |call|
            next unless namespaces.any?(call)

            add_offense(node) do |corrector|
              remove_term(corrector, call)
            end
          end
        end

        private

        def terms(node)
          node.each_descendant.select do |descendant|
            descendant.parent.and_type? && !descendant.and_type?
          end
        end

        def defined_calls(nodes)
          nodes.filter_map do |defined_node|
            subject = defined_node.first_argument
            subject if subject.type?(:const, :call)
          end
        end

        def namespaces(nodes)
          nodes.filter_map do |node|
            if node.respond_to?(:namespace)
              node.namespace
            elsif node.respond_to?(:receiver)
              node.receiver
            end
          end
        end

        def remove_term(corrector, term)
          term = term.parent until term.parent.and_type?
          range = if term == term.parent.children.last
                    rhs_range_to_remove(term)
                  else
                    lhs_range_to_remove(term)
                  end

          corrector.remove(range)
        end

        # If the redundant `defined?` node is the LHS of an `and` node,
        # the term as well as the subsequent `&&`/`and` operator will be removed.
        def lhs_range_to_remove(term)
          source = @processed_source.buffer.source

          pos = term.source_range.end_pos
          pos += 1 until source[..pos].end_with?(*OPERATORS)

          range_with_surrounding_space(
            range: term.source_range.with(end_pos: pos + 1),
            side: :right,
            newlines: false
          )
        end

        # If the redundant `defined?` node is the RHS of an `and` node,
        # the term as well as the preceding `&&`/`and` operator will be removed.
        def rhs_range_to_remove(term)
          source = @processed_source.buffer.source

          pos = term.source_range.begin_pos
          pos -= 1 until source[pos, 3].start_with?(*OPERATORS)

          range_with_surrounding_space(
            range: term.source_range.with(begin_pos: pos - 1),
            side: :right,
            newlines: false
          )
        end
      end
    end
  end
end
