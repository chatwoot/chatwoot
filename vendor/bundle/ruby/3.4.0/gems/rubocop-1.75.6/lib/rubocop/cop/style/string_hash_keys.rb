# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the use of strings as keys in hashes. The use of
      # symbols is preferred instead.
      #
      # @safety
      #   This cop is unsafe because while symbols are preferred for hash keys,
      #   there are instances when string keys are required.
      #
      # @example
      #   # bad
      #   { 'one' => 1, 'two' => 2, 'three' => 3 }
      #
      #   # good
      #   { one: 1, two: 2, three: 3 }
      class StringHashKeys < Base
        extend AutoCorrector

        MSG = 'Prefer symbols instead of strings as hash keys.'

        # @!method string_hash_key?(node)
        def_node_matcher :string_hash_key?, <<~PATTERN
          (pair (str _) _)
        PATTERN

        # @!method receive_environments_method?(node)
        def_node_matcher :receive_environments_method?, <<~PATTERN
          {
            ^^(send (const {nil? cbase} :IO) :popen ...)
            ^^(send (const {nil? cbase} :Open3)
                {:capture2 :capture2e :capture3 :popen2 :popen2e :popen3} ...)
            ^^^(send (const {nil? cbase} :Open3)
                {:pipeline :pipeline_r :pipeline_rw :pipeline_start :pipeline_w} ...)
            ^^(send {nil? (const {nil? cbase} :Kernel)} {:spawn :system} ...)
            ^^(send _ {:gsub :gsub!} ...)
          }
        PATTERN

        def on_pair(node)
          return unless string_hash_key?(node)

          key_content = node.key.str_content
          return unless key_content.valid_encoding?
          return if receive_environments_method?(node)

          add_offense(node.key) do |corrector|
            symbol_content = key_content.to_sym.inspect

            corrector.replace(node.key, symbol_content)
          end
        end
      end
    end
  end
end
