module Slim
  module Smart
    # Perform newline processing in the
    # expressions `[:slim, :text, type, Expression]`.
    #
    # @api private
    class Filter < ::Slim::Filter
      define_options smart_text: true,
                     smart_text_end_chars: '([{',
                     smart_text_begin_chars: ',.;:!?)]}'

      def initialize(opts = {})
        super
        @active = @prepend = @append = false
        @prepend_re = /\A#{chars_re(options[:smart_text_begin_chars])}/
        @append_re = /#{chars_re(options[:smart_text_end_chars])}\Z/
      end

      def call(exp)
        if options[:smart_text]
          super
        else
          exp
        end
      end

      def on_multi(*exps)
        # The [:multi] blocks serve two purposes.
        # On outer level, they collect the building blocks like
        # tags, verbatim text, and implicit/explicit text.
        # Within a text block, they collect the individual
        # lines in [:slim, :interpolate, string] blocks.
        #
        # Our goal here is to decide when we want to prepend and
        # append newlines to those individual interpolated lines.
        # We basically want the text to come out as it was originally entered,
        # while removing newlines next to the enclosing tags.
        #
        # On outer level, we choose to prepend every time, except
        # right after the opening tag or after other text block.
        # We also use the append flag to recognize the last expression
        # before the closing tag, as we don't want to append newline there.
        #
        # Within text block, we prepend only before the first line unless
        # the outer level tells us not to, and we append only after the last line,
        # unless the outer level tells us it is the last line before the closing tag.
        # Of course, this is later subject to the special begin/end characters
        # which may further suppress the newline at the corresponding line boundary.
        # Also note that the lines themselves are already correctly separated by newlines,
        # so we don't have to worry about that at all.
        block = [:multi]
        prev = nil
        last_exp = exps.reject{ |exp| exp.first == :newline }.last unless @active && @append
        exps.each do |exp|
          @append = exp.equal?(last_exp)
          if @active
            @prepend = false if prev
          else
            @prepend = prev && ( prev.first != :slim || prev[1] != :text )
          end
          block << compile(exp)
          prev = exp unless exp.first == :newline
        end
        block
      end

      def on_slim_text(type, content)
        @active = type != :verbatim
        [:slim, :text, type, compile(content)]
      ensure
        @active = false
      end

      def on_slim_text_inline(content)
        # Inline text is not wrapped in multi block, so set it up as if it was.
        @prepend = false
        @append = true
        on_slim_text(:inline, content)
      end

      def on_slim_interpolate(string)
        if @active
          string = "\n" + string if @prepend && string !~ @prepend_re
          string += "\n" if @append && string !~ @append_re
        end
        [:slim, :interpolate, string]
      end

      private

      def chars_re(string)
        Regexp.union(string.split(//))
      end
    end
  end
end
