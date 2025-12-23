# frozen_string_literal: true

require 'set'

module RuboCop
  module Cop
    module RSpec
      # Checks for stubbed test subjects.
      #
      # Checks nested subject stubs for innermost subject definition
      # when subject is also defined in parent example groups.
      #
      # @see https://robots.thoughtbot.com/don-t-stub-the-system-under-test
      # @see https://penelope.zone/2015/12/27/introducing-rspec-smells-and-where-to-find-them.html#smell-1-stubjec
      #
      # @example
      #   # bad
      #   describe Article do
      #     subject(:article) { Article.new }
      #
      #     it 'indicates that the author is unknown' do
      #       allow(article).to receive(:author).and_return(nil)
      #       expect(article.description).to include('by an unknown author')
      #     end
      #   end
      #
      #   # bad
      #   describe Article do
      #     subject(:foo) { Article.new }
      #
      #     context 'nested subject' do
      #       subject(:article) { Article.new }
      #
      #       it 'indicates that the author is unknown' do
      #         allow(article).to receive(:author).and_return(nil)
      #         expect(article.description).to include('by an unknown author')
      #       end
      #     end
      #   end
      #
      #   # good
      #   describe Article do
      #     subject(:article) { Article.new(author: nil) }
      #
      #     it 'indicates that the author is unknown' do
      #       expect(article.description).to include('by an unknown author')
      #     end
      #   end
      #
      class SubjectStub < Base
        include TopLevelGroup

        MSG = 'Do not stub methods of the object under test.'

        # @!method subject?(node)
        #   Find a named or unnamed subject definition
        #
        #   @example anonymous subject
        #     subject?(parse('subject { foo }').ast) do |name|
        #       name # => :subject
        #     end
        #
        #   @example named subject
        #     subject?(parse('subject(:thing) { foo }').ast) do |name|
        #       name # => :thing
        #     end
        #
        #   @param node [RuboCop::AST::Node]
        #
        #   @yield [Symbol] subject name
        def_node_matcher :subject?, <<~PATTERN
          (block
            (send nil?
              { #Subjects.all (sym $_) | $#Subjects.all }
            ) args ...)
        PATTERN

        # @!method let?(node)
        #   Find a memoized helper
        def_node_matcher :let?, <<~PATTERN
          (block
            (send nil? :let (sym $_)
            ) args ...)
        PATTERN

        # @!method message_expectation?(node, method_name)
        #   Match `allow` and `expect(...).to receive`
        #
        #   @example source that matches
        #     allow(foo).to  receive(:bar)
        #     allow(foo).to  receive(:bar).with(1)
        #     allow(foo).to  receive(:bar).with(1).and_return(2)
        #     expect(foo).to receive(:bar)
        #     expect(foo).to receive(:bar).with(1)
        #     expect(foo).to receive(:bar).with(1).and_return(2)
        #
        def_node_matcher :message_expectation?, <<~PATTERN
          (send
            {
              (send nil? { :expect :allow } (send nil? %))
              (send nil? :is_expected)
            }
            #Runners.all
            #message_expectation_matcher?
          )
        PATTERN

        # @!method message_expectation_matcher?(node)
        def_node_search :message_expectation_matcher?, <<~PATTERN
          (send nil? {
            :receive :receive_messages :receive_message_chain :have_received
            } ...)
        PATTERN

        def on_top_level_group(node)
          @explicit_subjects = find_all_explicit(node) { |n| subject?(n) }
          @subject_overrides = find_all_explicit(node) { |n| let?(n) }

          find_subject_expectations(node) do |stub|
            add_offense(stub)
          end
        end

        private

        def find_all_explicit(node)
          node.each_descendant(:block).with_object({}) do |child, h|
            name = yield(child)
            next unless name

            outer_example_group = child.each_ancestor(:block).find do |a|
              example_group?(a)
            end

            h[outer_example_group] ||= []
            h[outer_example_group] << name
          end
        end

        def find_subject_expectations(node, subject_names = [], &block)
          subject_names = [*subject_names, *@explicit_subjects[node]]
          subject_names -= @subject_overrides[node] if @subject_overrides[node]

          names = Set[*subject_names, :subject]
          expectation_detected = message_expectation?(node, names)
          return yield(node) if expectation_detected

          node.each_child_node(:send, :def, :block, :begin) do |child|
            find_subject_expectations(child, subject_names, &block)
          end
        end
      end
    end
  end
end
