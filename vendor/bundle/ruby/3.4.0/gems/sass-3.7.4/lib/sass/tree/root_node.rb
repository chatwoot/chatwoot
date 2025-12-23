module Sass
  module Tree
    # A static node that is the root node of the Sass document.
    class RootNode < Node
      # The Sass template from which this node was created
      #
      # @param template [String]
      attr_reader :template

      # @param template [String] The Sass template from which this node was created
      def initialize(template)
        super()
        @template = template
      end

      # Runs the dynamic Sass code and computes the CSS for the tree.
      #
      # @return [String] The compiled CSS.
      def render
        css_tree.css
      end

      # Runs the dynamic Sass code and computes the CSS for the tree, along with
      # the sourcemap.
      #
      # @return [(String, Sass::Source::Map)] The compiled CSS, as well as
      #   the source map. @see #render
      def render_with_sourcemap
        css_tree.css_with_sourcemap
      end

      private

      def css_tree
        Visitors::CheckNesting.visit(self)
        result = Visitors::Perform.visit(self)
        Visitors::CheckNesting.visit(result) # Check again to validate mixins
        result, extends = Visitors::Cssize.visit(result)
        Visitors::Extend.visit(result, extends)
        result
      end
    end
  end
end
