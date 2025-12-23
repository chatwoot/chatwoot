module Slim
  # In Slim you don't need to close any blocks:
  #
  #   - if Slim.awesome?
  #     | But of course it is!
  #
  # However, the parser is not smart enough (and that's a good thing) to
  # automatically insert end's where they are needed. Luckily, this filter
  # does *exactly* that (and it does it well!)
  #
  # @api private
  class EndInserter < Filter
    IF_RE = /\A(if|begin|unless|else|elsif|when|rescue|ensure)\b|\bdo\s*(\|[^\|]*\|)?\s*$/
    ELSE_RE = /\A(else|elsif|when|rescue|ensure)\b/
    END_RE = /\Aend\b/

    # Handle multi expression `[:multi, *exps]`
    #
    # @return [Array] Corrected Temple expression with ends inserted
    def on_multi(*exps)
      result = [:multi]
      # This variable is true if the previous line was
      # (1) a control code and (2) contained indented content.
      prev_indent = false

      exps.each do |exp|
        if control?(exp)
          raise(Temple::FilterError, 'Explicit end statements are forbidden') if exp[2] =~ END_RE

          # Two control code in a row. If this one is *not*
          # an else block, we should close the previous one.
          append_end(result) if prev_indent && exp[2] !~ ELSE_RE

          # Indent if the control code starts a block.
          prev_indent = exp[2] =~ IF_RE
        elsif exp[0] != :newline && prev_indent
          # This is *not* a control code, so we should close the previous one.
          # Ignores newlines because they will be inserted after each line.
          append_end(result)
          prev_indent = false
        end

        result << compile(exp)
      end

      # The last line can be a control code too.
      prev_indent ? append_end(result) : result
    end

    private

    # Appends an end
    def append_end(result)
      result << [:code, 'end']
    end

    # Checks if an expression is a Slim control code
    def control?(exp)
      exp[0] == :slim && exp[1] == :control
    end
  end
end
