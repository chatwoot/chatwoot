# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if an example group does not include any tests.
      #
      # @example usage
      #   # bad
      #   describe Bacon do
      #     let(:bacon)      { Bacon.new(chunkiness) }
      #     let(:chunkiness) { false                 }
      #
      #     context 'extra chunky' do   # flagged by rubocop
      #       let(:chunkiness) { true }
      #     end
      #
      #     it 'is chunky' do
      #       expect(bacon.chunky?).to be_truthy
      #     end
      #   end
      #
      #   # good
      #   describe Bacon do
      #     let(:bacon)      { Bacon.new(chunkiness) }
      #     let(:chunkiness) { false                 }
      #
      #     it 'is chunky' do
      #       expect(bacon.chunky?).to be_truthy
      #     end
      #   end
      #
      #   # good
      #   describe Bacon do
      #     pending 'will add tests later'
      #   end
      #
      class EmptyExampleGroup < Base
        extend AutoCorrector

        include RangeHelp

        MSG = 'Empty example group detected.'

        # @!method example_group_body(node)
        #   Match example group blocks and yield their body
        #
        #   @example source that matches
        #     describe 'example group' do
        #       it { is_expected.to be }
        #     end
        #
        #   @param node [RuboCop::AST::Node]
        #   @yield [RuboCop::AST::Node] example group body
        def_node_matcher :example_group_body, <<~PATTERN
          (block (send #rspec? #ExampleGroups.all ...) args $_)
        PATTERN

        # @!method example_or_group_or_include?(node)
        #   Match examples, example groups and includes
        #
        #   @example source that matches
        #     it { is_expected.to fly }
        #     describe('non-empty example groups too') { }
        #     it_behaves_like 'an animal'
        #     it_behaves_like('a cat') { let(:food) { 'milk' } }
        #     it_has_root_access
        #     skip
        #     it 'will be implemented later'
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :example_or_group_or_include?, <<~PATTERN
          {
            (block
              (send #rspec? {#Examples.all #ExampleGroups.all #Includes.all} ...)
            ...)
            (send nil? {#Examples.all #Includes.all} ...)
          }
        PATTERN

        # @!method examples_inside_block?(node)
        #   Match examples defined inside a block which is not a hook
        #
        #   @example source that matches
        #     %w(r g b).each do |color|
        #       it { is_expected.to have_color(color) }
        #     end
        #
        #   @example source that does not match
        #     before do
        #       it { is_expected.to fall_into_oblivion }
        #     end
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :examples_inside_block?, <<~PATTERN
          (block !(send nil? #Hooks.all ...) _ #examples?)
        PATTERN

        # @!method examples_directly_or_in_block?(node)
        #   Match examples or examples inside blocks
        #
        #   @example source that matches
        #     it { expect(drink).to be_cold }
        #     context('when winter') { it { expect(drink).to be_hot } }
        #     (1..5).each { |divisor| it { is_expected.to divide_by(divisor) } }
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :examples_directly_or_in_block?, <<~PATTERN
          {
            #example_or_group_or_include?
            #examples_inside_block?
          }
        PATTERN

        # @!method examples?(node)
        #   Matches examples defined in scopes where they could run
        #
        #   @example source that matches
        #     it { expect(myself).to be_run }
        #     describe { it { i_run_as_well } }
        #
        #   @example source that does not match
        #     before { it { whatever here won't run anyway } }
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :examples?, <<~PATTERN
          {
            #examples_directly_or_in_block?
            #examples_in_branches?
            (begin <#examples_directly_or_in_block? ...>)
            (begin <#examples_in_branches? ...>)
          }
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return if node.each_ancestor(:any_def).any?
          return if node.each_ancestor(:block).any? { |block| example?(block) }

          example_group_body(node) do |body|
            next unless offensive?(body)

            add_offense(node.send_node) do |corrector|
              corrector.remove(removed_range(node))
            end
          end
        end

        private

        def offensive?(body)
          return true unless body
          return false if conditionals_with_examples?(body)

          if body.type?(:if, :case)
            !examples_in_branches?(body)
          else
            !examples?(body)
          end
        end

        def conditionals_with_examples?(body)
          return false unless body.type?(:begin, :case)

          body.each_descendant(:if, :case).any? do |condition_node|
            examples_in_branches?(condition_node)
          end
        end

        def examples_in_branches?(condition_node)
          return false unless condition_node
          return false unless condition_node.type?(:if, :case)

          condition_node.branches.any? { |branch| examples?(branch) }
        end

        def removed_range(node)
          range_by_whole_lines(
            node.source_range,
            include_final_newline: true
          )
        end
      end
    end
  end
end
