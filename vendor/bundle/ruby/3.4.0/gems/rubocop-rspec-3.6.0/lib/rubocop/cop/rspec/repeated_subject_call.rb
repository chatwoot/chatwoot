# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for repeated calls to subject missing that it is memoized.
      #
      # @example
      #   # bad
      #   it do
      #     subject
      #     expect { subject }.to not_change { A.count }
      #   end
      #
      #   it do
      #     expect { subject }.to change { A.count }
      #     expect { subject }.to not_change { A.count }
      #   end
      #
      #   # good
      #   it do
      #     expect { my_method }.to change { A.count }
      #     expect { my_method }.to not_change { A.count }
      #   end
      #
      #   # also good
      #   it do
      #     expect { subject.a }.to change { A.count }
      #     expect { subject.b }.to not_change { A.count }
      #   end
      #
      class RepeatedSubjectCall < Base
        include TopLevelGroup

        MSG = 'Calls to subject are memoized, this block is misleading'

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
        def_node_matcher :subject?, <<-PATTERN
          (block
            (send nil?
              { #Subjects.all (sym $_) | $#Subjects.all }
            ) args ...)
        PATTERN

        # @!method subject_calls(node, method_name)
        def_node_search :subject_calls, <<~PATTERN
          (send nil? %)
        PATTERN

        def on_top_level_group(node)
          @subjects_by_node = detect_subjects_in_scope(node)

          detect_offenses_in_block(node)
        end

        private

        def detect_offense(subject_node)
          return if subject_node.chained?
          return if subject_node.parent.send_type?
          return unless (block_node = expect_block(subject_node))

          add_offense(block_node)
        end

        def expect_block(node)
          node.each_ancestor(:block).find { |block| block.method?(:expect) }
        end

        def detect_offenses_in_block(node, subject_names = [])
          subject_names = [*subject_names, *@subjects_by_node[node]]

          if example?(node)
            return detect_offenses_in_example(node, subject_names)
          end

          node.each_child_node(:send, :def, :block, :begin) do |child|
            detect_offenses_in_block(child, subject_names)
          end
        end

        def detect_offenses_in_example(node, subject_names)
          return unless node.body

          subjects_used = Hash.new(false)

          subject_calls(node.body, Set[*subject_names, :subject]).each do |call|
            if subjects_used[call.method_name]
              detect_offense(call)
            else
              subjects_used[call.method_name] = true
            end
          end
        end

        def detect_subjects_in_scope(node)
          node.each_descendant(:block).with_object({}) do |child, h|
            subject?(child) do |name|
              outer_example_group = child.each_ancestor(:block).find do |a|
                example_group?(a)
              end

              (h[outer_example_group] ||= []) << name
            end
          end
        end
      end
    end
  end
end
