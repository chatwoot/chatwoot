module Slim
  # @api private
  class Controls < Filter
    define_options :disable_capture

    IF_RE = /\A(if|unless)\b|\bdo\s*(\|[^\|]*\|)?\s*$/

    # Handle control expression `[:slim, :control, code, content]`
    #
    # @param [String] code Ruby code
    # @param [Array] content Temple expression
    # @return [Array] Compiled temple expression
    def on_slim_control(code, content)
      [:multi,
        [:code, code],
        compile(content)]
    end

    # Handle output expression `[:slim, :output, escape, code, content]`
    #
    # @param [Boolean] escape Escape html
    # @param [String] code Ruby code
    # @param [Array] content Temple expression
    # @return [Array] Compiled temple expression
    def on_slim_output(escape, code, content)
      if code =~ IF_RE
        tmp = unique_name

        [:multi,
         # Capture the result of the code in a variable. We can't do
         # `[:dynamic, code]` because it's probably not a complete
         # expression (which is a requirement for Temple).
         [:block, "#{tmp} = #{code}",

          # Capture the content of a block in a separate buffer. This means
          # that `yield` will not output the content to the current buffer,
          # but rather return the output.
          #
          # The capturing can be disabled with the option :disable_capture.
          # Output code in the block writes directly to the output buffer then.
          # Rails handles this by replacing the output buffer for helpers.
          options[:disable_capture] ? compile(content) : [:capture, unique_name, compile(content)]],

         # Output the content.
         [:escape, escape, [:dynamic, tmp]]]
      else
        [:multi, [:escape, escape, [:dynamic, code]], content]
      end
    end

    # Handle text expression `[:slim, :text, type, content]`
    #
    # @param [Symbol] type Text type
    # @param [Array] content Temple expression
    # @return [Array] Compiled temple expression
    def on_slim_text(type, content)
      compile(content)
    end
  end
end
