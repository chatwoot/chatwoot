module Slim
  module Smart
    # @api private
    class Parser < ::Slim::Parser
      define_options implicit_text: true

      def initialize(opts = {})
        super
        word_re = options[:implicit_text] ? '[_a-z0-9]' : '\p{Word}'
        attr_keys = Regexp.union(@attr_shortcut.keys.sort_by {|k| -k.size } )
        @attr_shortcut_re = /\A(#{attr_keys}+)((?:\p{Word}|-)*)/
        tag_keys = Regexp.union((@tag_shortcut.keys - @attr_shortcut.keys).sort_by {|k| -k.size } )
        @tag_re = /\A(?:#{attr_keys}(?=-*\p{Word})|#{tag_keys}|\*(?=[^\s]+)|(#{word_re}(?:#{word_re}|:|-)*#{word_re}|#{word_re}+))/
      end

      def unknown_line_indicator
        if @line =~ /\A>( ?)/
          # Found explicit text block.
          @stacks.last << [:slim, :text, :explicit, parse_text_block($', @indents.last + $1.size + 1)]
        else
          unless options[:implicit_text]
            syntax_error! 'Illegal shortcut' if @line =~ @attr_shortcut_re
            super
          end
          # Found implicit smart text block.
          if line = @lines.first
            indent = ( line =~ /\A\s*\Z/ ? @indents.last + 1 : get_indent(line) )
          end
          @stacks.last << [:slim, :text, :implicit, parse_text_block(@line, indent)]
        end
      end
    end
  end
end
