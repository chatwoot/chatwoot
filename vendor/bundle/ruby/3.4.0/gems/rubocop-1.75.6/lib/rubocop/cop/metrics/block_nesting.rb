# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks for excessive nesting of conditional and looping constructs.
      #
      # You can configure if blocks are considered using the `CountBlocks` and `CountModifierForms`
      # options. When both are set to `false` (the default) blocks and modifier forms are not
      # counted towards the nesting level. Set them to `true` to include these in the nesting level
      # calculation as well.
      #
      # The maximum level of nesting allowed is configurable.
      class BlockNesting < Base
        NESTING_BLOCKS = %i[case case_match if while while_post until until_post for resbody].freeze

        exclude_limit 'Max'

        def on_new_investigation
          return if processed_source.blank?

          max = cop_config['Max']
          check_nesting_level(processed_source.ast, max, 0)
        end

        private

        def check_nesting_level(node, max, current_level)
          if consider_node?(node)
            current_level += 1 if count_if_block?(node)
            if current_level > max
              self.max = current_level
              unless part_of_ignored_node?(node)
                add_offense(node, message: message(max)) { ignore_node(node) }
              end
            end
          end

          node.each_child_node do |child_node|
            check_nesting_level(child_node, max, current_level)
          end
        end

        def count_if_block?(node)
          return true unless node.if_type?
          return false if node.elsif?
          return count_modifier_forms? if node.modifier_form?

          true
        end

        def consider_node?(node)
          return true if NESTING_BLOCKS.include?(node.type)

          count_blocks? && node.any_block_type?
        end

        def message(max)
          "Avoid more than #{max} levels of block nesting."
        end

        def count_blocks?
          cop_config.fetch('CountBlocks', false)
        end

        def count_modifier_forms?
          cop_config.fetch('CountModifierForms', false)
        end
      end
    end
  end
end
