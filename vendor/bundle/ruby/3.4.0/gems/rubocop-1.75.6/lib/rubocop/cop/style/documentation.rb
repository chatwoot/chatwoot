# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for missing top-level documentation of classes and
      # modules. Classes with no body are exempt from the check and so are
      # namespace modules - modules that have nothing in their bodies except
      # classes, other modules, constant definitions or constant visibility
      # declarations.
      #
      # The documentation requirement is annulled if the class or module has
      # a `#:nodoc:` comment next to it. Likewise, `#:nodoc: all` does the
      # same for all its children.
      #
      # @example
      #   # bad
      #   class Person
      #     # ...
      #   end
      #
      #   module Math
      #   end
      #
      #   # good
      #   # Description/Explanation of Person class
      #   class Person
      #     # ...
      #   end
      #
      #   # allowed
      #   # Class without body
      #   class Person
      #   end
      #
      #   # Namespace - A namespace can be a class or a module
      #   # Containing a class
      #   module Namespace
      #     # Description/Explanation of Person class
      #     class Person
      #       # ...
      #     end
      #   end
      #
      #   # Containing constant visibility declaration
      #   module Namespace
      #     class Private
      #     end
      #
      #     private_constant :Private
      #   end
      #
      #   # Containing constant definition
      #   module Namespace
      #     Public = Class.new
      #   end
      #
      #   # Macro calls
      #   module Namespace
      #     extend Foo
      #   end
      #
      # @example AllowedConstants: ['ClassMethods']
      #
      #    # good
      #    module A
      #      module ClassMethods
      #        # ...
      #      end
      #    end
      #
      class Documentation < Base
        include DocumentationComment
        include RangeHelp

        MSG = 'Missing top-level documentation comment for `%<type>s %<identifier>s`.'

        # @!method constant_definition?(node)
        def_node_matcher :constant_definition?, '{class module casgn}'

        # @!method outer_module(node)
        def_node_search :outer_module, '(const (const nil? _) _)'

        # @!method constant_visibility_declaration?(node)
        def_node_matcher :constant_visibility_declaration?, <<~PATTERN
          (send nil? {:public_constant :private_constant} ({sym str} _))
        PATTERN

        # @!method include_statement?(node)
        def_node_matcher :include_statement?, <<~PATTERN
          (send nil? {:include :extend :prepend} const)
        PATTERN

        def on_class(node)
          return unless node.body

          check(node, node.body)
        end

        def on_module(node)
          check(node, node.body)
        end

        private

        def check(node, body)
          return if namespace?(body)
          return if documentation_comment?(node)
          return if constant_allowed?(node)
          return if nodoc_self_or_outer_module?(node)
          return if include_statement_only?(body)

          range = range_between(node.source_range.begin_pos, node.loc.name.end_pos)
          message = format(MSG, type: node.type, identifier: identifier(node))
          add_offense(range, message: message)
        end

        def nodoc_self_or_outer_module?(node)
          nodoc_comment?(node) ||
            (compact_namespace?(node) && nodoc_comment?(outer_module(node).first))
        end

        def include_statement_only?(body)
          return true if include_statement?(body)

          body.respond_to?(:children) && body.children.all? { |node| include_statement_only?(node) }
        end

        def namespace?(node)
          return false unless node

          if node.begin_type?
            node.children.all? { |child| constant_declaration?(child) }
          else
            constant_definition?(node)
          end
        end

        def constant_declaration?(node)
          constant_definition?(node) || constant_visibility_declaration?(node)
        end

        def constant_allowed?(node)
          allowed_constants.include?(node.identifier.short_name)
        end

        def compact_namespace?(node)
          node.loc.name.source.include?('::')
        end

        # First checks if the :nodoc: comment is associated with the
        # class/module. Unless the element is tagged with :nodoc:, the search
        # proceeds to check its ancestors for :nodoc: all.
        # Note: How end-of-line comments are associated with code changed in
        # parser-2.2.0.4.
        def nodoc_comment?(node, require_all: false)
          return false unless node&.children&.first

          nodoc = nodoc(node)

          return true if same_line?(nodoc, node) && nodoc?(nodoc, require_all: require_all)

          nodoc_comment?(node.parent, require_all: true)
        end

        def nodoc?(comment, require_all: false)
          /^#\s*:nodoc:#{"\s+all\s*$" if require_all}/.match?(comment.text)
        end

        def nodoc(node)
          processed_source.ast_with_comments[node.children.first].first
        end

        def allowed_constants
          @allowed_constants ||= cop_config.fetch('AllowedConstants', []).map(&:intern)
        end

        def identifier(node)
          # Get the fully qualified identifier for a class/module
          nodes = [node, *node.each_ancestor(:class, :module)]
          identifier = nodes.reverse_each.flat_map { |n| qualify_const(n.identifier) }.join('::')

          identifier.sub('::::', '::')
        end

        def qualify_const(node)
          return if node.nil?

          if node.type?(:cbase, :self, :call) || node.variable?
            node.source
          else
            [qualify_const(node.namespace), node.short_name].compact
          end
        end
      end
    end
  end
end
