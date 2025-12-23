# frozen_string_literal: true

module RuboCop
  module RSpec
    # Wrapper for RSpec hook
    class Hook < Concept
      # @!method extract_metadata(node)
      def_node_matcher :extract_metadata, <<~PATTERN
        (block
          (send _ _ #valid_scope? ? $...) ...
        )
      PATTERN

      def name
        node.method_name
      end

      def knowable_scope?
        scope_argument.nil? ||
          scope_argument.sym_type? ||
          scope_argument.hash_type?
      end

      def example?
        scope.equal?(:each)
      end

      def scope
        return :each if scope_argument&.hash_type?

        case scope_name
        when nil, :each, :example then :each
        when :context, :all       then :context
        when :suite               then :suite
        end
      end

      def metadata
        (extract_metadata(node) || [])
          .map { |meta| transform_metadata(meta) }
          .flatten
          .inject(&:merge)
      end

      private

      def valid_scope?(node)
        node.sym_type? && Language::HookScopes.all(node.value)
      end

      def transform_metadata(meta)
        if meta.sym_type?
          { meta => true }
        else
          # This check is to be able to compare those two hooks:
          #
          #   before(:example, :special) { ... }
          #   before(:example, special: true) { ... }
          #
          # In the second case it's a node with a pair that has a value
          # of a `true_type?`.
          meta.pairs.map { |pair| { pair.key => transform_true(pair.value) } }
        end
      end

      def transform_true(node)
        return true if node.true_type?

        node
      end

      def scope_name
        scope_argument.to_a.first
      end

      def scope_argument
        node.send_node.first_argument
      end
    end
  end
end
