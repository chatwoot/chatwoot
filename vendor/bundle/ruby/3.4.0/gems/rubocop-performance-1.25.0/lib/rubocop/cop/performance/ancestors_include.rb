# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies usages of `ancestors.include?` and change them to use `<=` instead.
      #
      # @safety
      #   This cop is unsafe because it can't tell whether the receiver is a class or an object.
      #   e.g. the false positive was for `Nokogiri::XML::Node#ancestors`.
      #
      # @example
      #   # bad
      #   A.ancestors.include?(B)
      #
      #   # good
      #   A <= B
      #
      class AncestorsInclude < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `<=` instead of `ancestors.include?`.'
        RESTRICT_ON_SEND = %i[include?].freeze

        def_node_matcher :ancestors_include_candidate?, <<~PATTERN
          (send (send $_subclass :ancestors) :include? $_superclass)
        PATTERN

        def on_send(node)
          return unless (subclass, superclass = ancestors_include_candidate?(node))
          return if subclass && !subclass.const_type?

          add_offense(range(node)) do |corrector|
            subclass_source = subclass ? subclass.source : 'self'

            corrector.replace(node, "#{subclass_source} <= #{superclass.source}")
          end
        end

        private

        def range(node)
          location_of_ancestors = node.children[0].loc.selector.begin_pos
          end_location = node.loc.selector.end_pos

          range_between(location_of_ancestors, end_location)
        end
      end
    end
  end
end
