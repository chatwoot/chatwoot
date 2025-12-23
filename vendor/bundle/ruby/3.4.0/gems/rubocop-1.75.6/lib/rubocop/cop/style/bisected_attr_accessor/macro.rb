# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      class BisectedAttrAccessor
        # Representation of an `attr_reader`, `attr_writer` or `attr` macro
        # for use by `Style/BisectedAttrAccessor`.
        # @api private
        class Macro
          include VisibilityHelp

          attr_reader :node, :attrs, :bisection

          def self.macro?(node)
            node.method?(:attr_reader) || node.method?(:attr_writer) || node.method?(:attr)
          end

          def initialize(node)
            @node = node
            @attrs = node.arguments.to_h { |attr| [attr.source, attr] }
            @bisection = []
          end

          def bisect(*names)
            @bisection = attrs.slice(*names).values
          end

          def attr_names
            @attr_names ||= attrs.keys
          end

          def bisected_names
            bisection.map(&:source)
          end

          def visibility
            @visibility ||= node_visibility(node)
          end

          def reader?
            node.method?(:attr_reader) || node.method?(:attr)
          end

          def writer?
            node.method?(:attr_writer)
          end

          def all_bisected?
            rest.none?
          end

          def rest
            @rest ||= attr_names - bisected_names
          end
        end
      end
    end
  end
end
