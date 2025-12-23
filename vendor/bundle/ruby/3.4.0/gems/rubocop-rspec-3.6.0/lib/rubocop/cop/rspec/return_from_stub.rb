# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for consistent style of stub's return setting.
      #
      # Enforces either `and_return` or block-style return in the cases
      # where the returned value is constant. Ignores dynamic returned values
      # are the result would be different
      #
      # This cop can be configured using the `EnforcedStyle` option
      #
      # @example `EnforcedStyle: and_return` (default)
      #   # bad
      #   allow(Foo).to receive(:bar) { "baz" }
      #   expect(Foo).to receive(:bar) { "baz" }
      #
      #   # good
      #   allow(Foo).to receive(:bar).and_return("baz")
      #   expect(Foo).to receive(:bar).and_return("baz")
      #   # also good as the returned value is dynamic
      #   allow(Foo).to receive(:bar) { bar.baz }
      #
      # @example `EnforcedStyle: block`
      #   # bad
      #   allow(Foo).to receive(:bar).and_return("baz")
      #   expect(Foo).to receive(:bar).and_return("baz")
      #
      #   # good
      #   allow(Foo).to receive(:bar) { "baz" }
      #   expect(Foo).to receive(:bar) { "baz" }
      #   # also good as the returned value is dynamic
      #   allow(Foo).to receive(:bar).and_return(bar.baz)
      #
      class ReturnFromStub < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG_AND_RETURN = 'Use `and_return` for static values.'
        MSG_BLOCK = 'Use block for static values.'
        RESTRICT_ON_SEND = %i[and_return].freeze

        # @!method contains_stub?(node)
        def_node_search :contains_stub?, '(send nil? :receive (...))'

        # @!method stub_with_block?(node)
        def_node_matcher :stub_with_block?, '(block #contains_stub? ...)'

        # @!method and_return_value(node)
        def_node_search :and_return_value, <<~PATTERN
          $(send _ :and_return $(...))
        PATTERN

        def on_send(node)
          return unless style == :block
          return unless contains_stub?(node)

          check_and_return_call(node)
        end

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless style == :and_return
          return unless stub_with_block?(node)

          check_block_body(node)
        end

        private

        def check_and_return_call(node)
          and_return_value(node) do |and_return, args|
            unless dynamic?(args)
              add_offense(and_return.loc.selector, message: MSG_BLOCK) do |corr|
                AndReturnCallCorrector.new(and_return).call(corr)
              end
            end
          end
        end

        def check_block_body(block)
          body = block.body
          return if dynamic?(body)

          add_offense(block.loc.begin, message: MSG_AND_RETURN) do |corrector|
            BlockBodyCorrector.new(block).call(corrector)
          end
        end

        def dynamic?(node)
          node && !node.recursive_literal_or_const?
        end

        # :nodoc:
        class AndReturnCallCorrector
          def initialize(node)
            @node = node
            @receiver = node.receiver
            @arg = node.first_argument
          end

          def call(corrector)
            # Heredoc autocorrection is not yet implemented.
            return if heredoc?

            corrector.replace(range, " { #{replacement} }")
          end

          private

          attr_reader :node, :receiver, :arg

          def heredoc?
            arg.loc.is_a?(Parser::Source::Map::Heredoc)
          end

          def range
            Parser::Source::Range.new(
              node.source_range.source_buffer,
              receiver.source_range.end_pos,
              node.source_range.end_pos
            )
          end

          def replacement
            if hash_without_braces?
              "{ #{arg.source} }"
            else
              arg.source
            end
          end

          def hash_without_braces?
            arg.hash_type? && !arg.braces?
          end
        end

        # :nodoc:
        class BlockBodyCorrector
          def initialize(block)
            @block = block
            @node = block.parent
            @body = block.body || NULL_BLOCK_BODY
          end

          def call(corrector)
            # Heredoc autocorrection is not yet implemented.
            return if heredoc?

            corrector.replace(
              block,
              "#{block.send_node.source}.and_return(#{body.source})"
            )
          end

          private

          attr_reader :node, :block, :body

          def heredoc?
            body.loc.is_a?(Parser::Source::Map::Heredoc)
          end

          NULL_BLOCK_BODY = Struct.new(:loc, :source).new(nil, 'nil')
          private_constant :NULL_BLOCK_BODY
        end
      end
    end
  end
end
