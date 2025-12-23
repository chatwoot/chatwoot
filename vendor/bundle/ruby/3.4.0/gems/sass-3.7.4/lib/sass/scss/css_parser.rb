require 'sass/script/css_parser'

module Sass
  module SCSS
    # This is a subclass of {Parser} which only parses plain CSS.
    # It doesn't support any Sass extensions, such as interpolation,
    # parent references, nested selectors, and so forth.
    # It does support all the same CSS hacks as the SCSS parser, though.
    class CssParser < StaticParser
      private

      def placeholder_selector; nil; end
      def parent_selector; nil; end
      def interpolation(warn_for_color = false); nil; end
      def use_css_import?; true; end

      def block_contents(node, context)
        if node.is_a?(Sass::Tree::DirectiveNode) && node.normalized_name == '@keyframes'
          context = :keyframes
        end
        super(node, context)
      end

      def block_child(context)
        case context
        when :ruleset
          declaration
        when :stylesheet
          directive || ruleset
        when :directive
          directive || declaration_or_ruleset
        when :keyframes
          keyframes_ruleset
        end
      end

      def nested_properties!(node)
        expected('expression (e.g. 1px, bold)')
      end

      def ruleset
        start_pos = source_position
        return unless (selector = selector_comma_sequence)
        block(node(Sass::Tree::RuleNode.new(selector, range(start_pos)), start_pos), :ruleset)
      end

      def keyframes_ruleset
        start_pos = source_position
        return unless (selector = keyframes_selector)
        block(
          node(
            Sass::Tree::KeyframeRuleNode.new(
              Sass::Util.strip_except_escapes(selector)),
            start_pos),
          :ruleset)
      end

      @sass_script_parser = Sass::Script::CssParser
    end
  end
end
