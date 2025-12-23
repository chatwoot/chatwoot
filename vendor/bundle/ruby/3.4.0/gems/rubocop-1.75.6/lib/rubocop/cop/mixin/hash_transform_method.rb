# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for Style/HashTransformKeys and
    # Style/HashTransformValues
    module HashTransformMethod
      extend NodePattern::Macros

      RESTRICT_ON_SEND = %i[[] to_h].freeze

      # Internal helper class to hold match data
      Captures = Struct.new(:transformed_argname, :transforming_body_expr, :unchanged_body_expr) do
        def noop_transformation?
          transforming_body_expr.lvar_type? &&
            transforming_body_expr.children == [transformed_argname]
        end

        def transformation_uses_both_args?
          transforming_body_expr.descendants.include?(unchanged_body_expr)
        end

        def use_transformed_argname?
          transforming_body_expr.each_descendant(:lvar).any? do |node|
            node.source == transformed_argname.to_s
          end
        end
      end

      # Internal helper class to hold autocorrect data
      Autocorrection = Struct.new(:match, :block_node, :leading, :trailing) do
        def self.from_each_with_object(node, match)
          new(match, node, 0, 0)
        end

        def self.from_hash_brackets_map(node, match)
          new(match, node.children.last, 'Hash['.length, ']'.length)
        end

        def self.from_map_to_h(node, match)
          if node.parent&.block_type? && node.parent.send_node == node
            strip_trailing_chars = 0
          else
            map_range = node.children.first.source_range
            node_range = node.source_range
            strip_trailing_chars = node_range.end_pos - map_range.end_pos
          end

          new(match, node.children.first, 0, strip_trailing_chars)
        end

        def self.from_to_h(node, match)
          new(match, node, 0, 0)
        end

        def strip_prefix_and_suffix(node, corrector)
          expression = node.source_range
          corrector.remove_leading(expression, leading)
          corrector.remove_trailing(expression, trailing)
        end

        def set_new_method_name(new_method_name, corrector)
          range = block_node.send_node.loc.selector
          if (send_end = block_node.send_node.loc.end)
            # If there are arguments (only true in the `each_with_object`
            # case)
            range = range.begin.join(send_end)
          end
          corrector.replace(range, new_method_name)
        end

        def set_new_arg_name(transformed_argname, corrector)
          corrector.replace(block_node.arguments, "|#{transformed_argname}|")
        end

        def set_new_body_expression(transforming_body_expr, corrector)
          body_source = transforming_body_expr.source
          if transforming_body_expr.hash_type? && !transforming_body_expr.braces?
            body_source = "{ #{body_source} }"
          end

          corrector.replace(block_node.body, body_source)
        end
      end

      # @!method array_receiver?(node)
      def_node_matcher :array_receiver?, <<~PATTERN
        {(array ...) (send _ :each_with_index) (send _ :with_index _ ?) (send _ :zip ...)}
      PATTERN

      def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
        on_bad_each_with_object(node) do |*match|
          handle_possible_offense(node, match, 'each_with_object')
        end

        return if target_ruby_version < 2.6

        on_bad_to_h(node) { |*match| handle_possible_offense(node, match, 'to_h {...}') }
      end

      def on_send(node)
        on_bad_hash_brackets_map(node) do |*match|
          handle_possible_offense(node, match, 'Hash[_.map {...}]')
        end
        on_bad_map_to_h(node) { |*match| handle_possible_offense(node, match, 'map {...}.to_h') }
      end

      def on_csend(node)
        on_bad_map_to_h(node) { |*match| handle_possible_offense(node, match, 'map {...}.to_h') }
      end

      private

      # @abstract Implemented with `def_node_matcher`
      def on_bad_each_with_object(_node)
        raise NotImplementedError
      end

      # @abstract Implemented with `def_node_matcher`
      def on_bad_hash_brackets_map(_node)
        raise NotImplementedError
      end

      # @abstract Implemented with `def_node_matcher`
      def on_bad_map_to_h(_node)
        raise NotImplementedError
      end

      # @abstract Implemented with `def_node_matcher`
      def on_bad_to_h(_node)
        raise NotImplementedError
      end

      def handle_possible_offense(node, match, match_desc)
        captures = extract_captures(match)

        # If key didn't actually change either, this is most likely a false
        # positive (receiver isn't a hash).
        return if captures.noop_transformation?

        # Can't `transform_keys` if key transformation uses value, or
        # `transform_values` if value transformation uses key.
        return if captures.transformation_uses_both_args?

        return unless captures.use_transformed_argname?

        message = "Prefer `#{new_method_name}` over `#{match_desc}`."
        add_offense(node, message: message) do |corrector|
          correction = prepare_correction(node)
          execute_correction(corrector, node, correction)
        end
      end

      # @abstract
      #
      # @return [Captures]
      def extract_captures(_match)
        raise NotImplementedError
      end

      # @abstract
      #
      # @return [String]
      def new_method_name
        raise NotImplementedError
      end

      def prepare_correction(node)
        if (match = on_bad_each_with_object(node))
          Autocorrection.from_each_with_object(node, match)
        elsif (match = on_bad_hash_brackets_map(node))
          Autocorrection.from_hash_brackets_map(node, match)
        elsif (match = on_bad_map_to_h(node))
          Autocorrection.from_map_to_h(node, match)
        elsif (match = on_bad_to_h(node))
          Autocorrection.from_to_h(node, match)
        else
          raise 'unreachable'
        end
      end

      def execute_correction(corrector, node, correction)
        correction.strip_prefix_and_suffix(node, corrector)
        correction.set_new_method_name(new_method_name, corrector)

        captures = extract_captures(correction.match)
        correction.set_new_arg_name(captures.transformed_argname, corrector)
        correction.set_new_body_expression(captures.transforming_body_expr, corrector)
      end
    end
  end
end
