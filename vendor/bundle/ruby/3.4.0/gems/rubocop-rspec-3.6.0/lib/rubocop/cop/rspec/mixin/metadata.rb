# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Helper methods to find RSpec metadata.
      module Metadata
        extend RuboCop::NodePattern::Macros

        include RuboCop::RSpec::Language

        # @!method rspec_metadata(node)
        def_node_matcher :rspec_metadata, <<~PATTERN
          (block
            (send
              #rspec? {#Examples.all #ExampleGroups.all #SharedGroups.all #Hooks.all} _ $...)
            ...)
        PATTERN

        # @!method rspec_configure(node)
        def_node_matcher :rspec_configure, <<~PATTERN
          (block (send #rspec? :configure) (args (arg $_)) ...)
        PATTERN

        # @!method metadata_in_block(node)
        def_node_search :metadata_in_block, <<~PATTERN
          (send (lvar %) #Hooks.all _ $...)
        PATTERN

        def on_block(node)
          rspec_configure(node) do |block_var|
            metadata_in_block(node, block_var) do |metadata_arguments|
              on_metadata_arguments(metadata_arguments)
            end
          end

          rspec_metadata(node) do |metadata_arguments|
            on_metadata_arguments(metadata_arguments)
          end
        end
        alias on_numblock on_block

        def on_metadata(_symbols, _hash)
          raise ::NotImplementedError
        end

        private

        def on_metadata_arguments(metadata_arguments)
          if metadata_arguments.last&.hash_type?
            *metadata_arguments, hash = metadata_arguments
            on_metadata(metadata_arguments, hash)
          else
            on_metadata(metadata_arguments, nil)
          end
        end
      end
    end
  end
end
