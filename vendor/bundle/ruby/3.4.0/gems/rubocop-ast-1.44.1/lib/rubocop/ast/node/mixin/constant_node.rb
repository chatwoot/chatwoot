# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that deal with constants:
    # `const`, `casgn`.
    module ConstantNode
      # @return [Node, nil] the node associated with the scope (e.g. cbase, const, ...)
      def namespace
        children[0]
      end

      # @return [Symbol] the demodulized name of the constant: "::Foo::Bar" => :Bar
      def short_name
        children[1]
      end

      # @return [Boolean] if the constant is a Module / Class, according to the standard convention.
      #                   Note: some classes might have uppercase in which case this method
      #                         returns false
      def module_name?
        short_name.match?(/[[:lower:]]/)
      end
      alias class_name? module_name?

      # @return [Boolean] if the constant starts with `::` (aka s(:cbase))
      def absolute?
        return false unless namespace

        each_path.first.cbase_type?
      end

      # @return [Boolean] if the constant does not start with `::` (aka s(:cbase))
      def relative?
        !absolute?
      end

      # Yield nodes for the namespace
      #
      #   For `::Foo::Bar::BAZ` => yields:
      #      s(:cbase), then
      #      s(:const, :Foo), then
      #      s(:const, s(:const, :Foo), :Bar)
      def each_path(&block)
        return to_enum(__method__) unless block

        descendants = []
        last = self
        loop do
          last = last.children.first
          break if last.nil?

          descendants << last
          break unless last.const_type?
        end
        descendants.reverse_each(&block)

        self
      end
    end
  end
end
