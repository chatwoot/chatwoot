# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBot
      # Always declare attribute values as blocks.
      #
      # @example
      #   # bad
      #   kind [:active, :rejected].sample
      #
      #   # good
      #   kind { [:active, :rejected].sample }
      #
      #   # bad
      #   closed_at 1.day.from_now
      #
      #   # good
      #   closed_at { 1.day.from_now }
      #
      #   # bad
      #   count 1
      #
      #   # good
      #   count { 1 }
      #
      class AttributeDefinedStatically < ::RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Use a block to declare attribute values.'

        # @!method value_matcher(node)
        def_node_matcher :value_matcher, <<~PATTERN
          (send _ !#reserved_method? $...)
        PATTERN

        # @!method factory_attributes(node)
        def_node_matcher :factory_attributes, <<~PATTERN
          (block (send _ #attribute_defining_method? ...) _ { (begin $...) $(send ...) } )
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          attributes = factory_attributes(node) || []
          attributes = [attributes] unless attributes.is_a?(Array) # rubocop:disable Style/ArrayCoercion, Lint/RedundantCopDisableDirective

          attributes.each do |attribute|
            next unless offensive_receiver?(attribute.receiver, node)
            next if proc?(attribute) || association?(attribute.first_argument)

            add_offense(attribute) do |corrector|
              autocorrect(corrector, attribute)
            end
          end
        end

        private

        def autocorrect(corrector, node)
          if node.parenthesized?
            autocorrect_replacing_parens(corrector, node)
          else
            autocorrect_without_parens(corrector, node)
          end
        end

        def offensive_receiver?(receiver, node)
          receiver.nil? ||
            receiver.self_type? ||
            receiver_matches_first_block_argument?(receiver, node)
        end

        def receiver_matches_first_block_argument?(receiver, node)
          first_block_argument = node.first_argument

          !first_block_argument.nil? &&
            receiver.lvar_type? &&
            receiver.node_parts == first_block_argument.node_parts
        end

        def proc?(attribute)
          value_matcher(attribute).to_a.all?(&:block_pass_type?)
        end

        # @!method association?(node)
        def_node_matcher :association?, '(hash <(pair (sym :factory) _) ...>)'

        def autocorrect_replacing_parens(corrector, node)
          left_braces, right_braces = braces(node)

          corrector.replace(node.location.begin, " #{left_braces}")
          corrector.replace(node.location.end, right_braces)
        end

        def autocorrect_without_parens(corrector, node)
          left_braces, right_braces = braces(node)

          argument = node.first_argument
          expression = argument.source_range
          corrector.insert_before(expression, left_braces)
          corrector.insert_after(expression, right_braces)
        end

        def braces(node)
          if value_hash_without_braces?(node.first_argument)
            ['{ { ', ' } }']
          else
            ['{ ', ' }']
          end
        end

        def value_hash_without_braces?(node)
          node.hash_type? && !node.braces?
        end

        def reserved_method?(method_name)
          RuboCop::FactoryBot.reserved_methods.include?(method_name)
        end

        def attribute_defining_method?(method_name)
          RuboCop::FactoryBot.attribute_defining_methods
            .include?(method_name)
        end
      end
    end
  end
end
