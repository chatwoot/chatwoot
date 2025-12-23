# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for consistent style for shared example names.
      #
      # Enforces either `string` or `symbol` for shared example names.
      #
      # This cop can be configured using the `EnforcedStyle` option
      #
      # @example `EnforcedStyle: string` (default)
      #   # bad
      #   it_behaves_like :foo_bar_baz
      #   it_should_behave_like :foo_bar_baz
      #   shared_examples :foo_bar_baz
      #   shared_examples_for :foo_bar_baz
      #   include_examples :foo_bar_baz
      #
      #   # good
      #   it_behaves_like 'foo bar baz'
      #   it_should_behave_like 'foo bar baz'
      #   shared_examples 'foo bar baz'
      #   shared_examples_for 'foo bar baz'
      #   include_examples 'foo bar baz'
      #
      # @example `EnforcedStyle: symbol`
      #   # bad
      #   it_behaves_like 'foo bar baz'
      #   it_should_behave_like 'foo bar baz'
      #   shared_examples 'foo bar baz'
      #   shared_examples_for 'foo bar baz'
      #   include_examples 'foo bar baz'
      #
      #   # good
      #   it_behaves_like :foo_bar_baz
      #   it_should_behave_like :foo_bar_baz
      #   shared_examples :foo_bar_baz
      #   shared_examples_for :foo_bar_baz
      #   include_examples :foo_bar_baz
      #
      class SharedExamples < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        # @!method shared_examples(node)
        def_node_matcher :shared_examples, <<~PATTERN
          {
            (send #rspec? #SharedGroups.all $_ ...)
            (send nil? #Includes.all $_ ...)
          }
        PATTERN

        def on_send(node)
          shared_examples(node) do |ast_node|
            next unless offense?(ast_node)

            checker = new_checker(ast_node)
            add_offense(ast_node, message: checker.message) do |corrector|
              corrector.replace(ast_node, checker.preferred_style)
            end
          end
        end

        private

        def offense?(ast_node)
          if style == :symbol
            ast_node.str_type?
          else # string
            ast_node.sym_type?
          end
        end

        def new_checker(ast_node)
          if style == :symbol
            SymbolChecker.new(ast_node)
          else # string
            StringChecker.new(ast_node)
          end
        end

        # :nodoc:
        class SymbolChecker
          MSG = 'Prefer %<prefer>s over `%<current>s` ' \
                'to symbolize shared examples.'

          attr_reader :node

          def initialize(node)
            @node = node
          end

          def message
            format(MSG, prefer: preferred_style, current: node.value.inspect)
          end

          def preferred_style
            ":#{node.value.to_s.downcase.tr(' ', '_')}"
          end
        end

        # :nodoc:
        class StringChecker
          MSG = 'Prefer %<prefer>s over `%<current>s` ' \
                'to titleize shared examples.'

          attr_reader :node

          def initialize(node)
            @node = node
          end

          def message
            format(MSG, prefer: preferred_style, current: node.value.inspect)
          end

          def preferred_style
            "'#{node.value.to_s.tr('_', ' ')}'"
          end
        end
      end
    end
  end
end
