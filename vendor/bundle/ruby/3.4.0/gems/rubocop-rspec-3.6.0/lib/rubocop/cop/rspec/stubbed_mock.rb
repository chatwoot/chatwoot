# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that message expectations do not have a configured response.
      #
      # @example
      #   # bad
      #   expect(foo).to receive(:bar).with(42).and_return("hello world")
      #
      #   # good (without spies)
      #   allow(foo).to receive(:bar).with(42).and_return("hello world")
      #   expect(foo).to receive(:bar).with(42)
      #
      class StubbedMock < Base
        MSG = 'Prefer %<replacement>s over `%<method_name>s` when ' \
              'configuring a response.'
        RESTRICT_ON_SEND = %i[to].freeze

        # @!method message_expectation?(node)
        #   Match message expectation matcher
        #
        #   @example source that matches
        #     receive(:foo)
        #
        #   @example source that matches
        #     receive_message_chain(:foo, :bar)
        #
        #   @example source that matches
        #     receive(:foo).with('bar')
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :message_expectation?, <<~PATTERN
          {
            (send nil? { :receive :receive_message_chain } ...)  # receive(:foo)
            (send (send nil? :receive ...) :with ...)            # receive(:foo).with('bar')
          }
        PATTERN

        # @!method configured_response?(node)
        def_node_matcher :configured_response?, <<~PATTERN
          { :and_return :and_raise :and_throw :and_yield
            :and_call_original :and_wrap_original }
        PATTERN

        # @!method expectation(node)
        #   Match expectation
        #
        #   @example source that matches
        #     is_expected.to be_in_the_bar
        #
        #   @example source that matches
        #     expect(cocktail).to contain_exactly(:fresh_orange_juice, :campari)
        #
        #   @example source that matches
        #     expect_any_instance_of(Officer).to be_alert
        #
        #   @param node [RuboCop::AST::Node]
        #   @yield [RuboCop::AST::Node] expectation, method name, matcher
        def_node_matcher :expectation, <<~PATTERN
          (send
            $(send nil? $#Expectations.all ...)
            :to $_)
        PATTERN

        # @!method matcher_with_configured_response(node)
        #   Match matcher with a configured response
        #
        #   @example source that matches
        #     receive(:foo).and_return('bar')
        #
        #   @example source that matches
        #     receive(:lower).and_raise(SomeError)
        #
        #   @example source that matches
        #     receive(:redirect).and_call_original
        #
        #   @param node [RuboCop::AST::Node]
        #   @yield [RuboCop::AST::Node] matcher
        def_node_matcher :matcher_with_configured_response, <<~PATTERN
          (send #message_expectation? #configured_response? _)
        PATTERN

        # @!method matcher_with_return_block(node)
        #   Match matcher with a return block
        #
        #   @example source that matches
        #     receive(:foo) { 'bar' }
        #
        #   @param node [RuboCop::AST::Node]
        #   @yield [RuboCop::AST::Node] matcher
        def_node_matcher :matcher_with_return_block, <<~PATTERN
          (block #message_expectation? (args) _)  # receive(:foo) { 'bar' }
        PATTERN

        # @!method matcher_with_hash(node)
        #   Match matcher with a configured response defined as a hash
        #
        #   @example source that matches
        #     receive_messages(foo: 'bar', baz: 'qux')
        #
        #   @example source that matches
        #     receive_message_chain(:foo, bar: 'baz')
        #
        #   @param node [RuboCop::AST::Node]
        #   @yield [RuboCop::AST::Node] matcher
        def_node_matcher :matcher_with_hash, <<~PATTERN
          {
            (send nil? :receive_messages hash)           # receive_messages(foo: 'bar', baz: 'qux')
            (send nil? :receive_message_chain ... hash)  # receive_message_chain(:foo, bar: 'baz')
          }
        PATTERN

        # @!method matcher_with_blockpass(node)
        #   Match matcher with a configured response in block-pass
        #
        #   @example source that matches
        #     receive(:foo, &canned)
        #
        #   @example source that matches
        #     receive_message_chain(:foo, :bar, &canned)
        #
        #   @example source that matches
        #     receive(:foo).with('bar', &canned)
        #
        #   @param node [RuboCop::AST::Node]
        #   @yield [RuboCop::AST::Node] matcher
        def_node_matcher :matcher_with_blockpass, <<~PATTERN
          {
            (send nil? { :receive :receive_message_chain } ... block_pass)  # receive(:foo, &canned)
            (send (send nil? :receive ...) :with ... block_pass)            # receive(:foo).with('foo', &canned)
          }
        PATTERN

        def on_send(node)
          expectation(node) do |expectation, method_name, matcher|
            on_expectation(expectation, method_name, matcher)
          end
        end

        private

        def on_expectation(expectation, method_name, matcher)
          flag_expectation = lambda do
            add_offense(expectation, message: msg(method_name))
          end

          matcher_with_configured_response(matcher, &flag_expectation)
          matcher_with_return_block(matcher, &flag_expectation)
          matcher_with_hash(matcher, &flag_expectation)
          matcher_with_blockpass(matcher, &flag_expectation)
        end

        def msg(method_name)
          format(
            MSG,
            method_name: method_name,
            replacement: replacement(method_name)
          )
        end

        def replacement(method_name)
          case method_name
          when :expect
            '`allow`'
          when :is_expected
            '`allow(subject)`'
          when :expect_any_instance_of
            '`allow_any_instance_of`'
          else
            'an allow statement'
          end
        end
      end
    end
  end
end
