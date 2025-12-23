module Slim
  # Base class for Temple filters used in Slim
  #
  # This base filter passes everything through and allows
  # to override only some methods without affecting the rest
  # of the expression.
  #
  # @api private
  class Filter < Temple::HTML::Filter
    # Pass-through handler
    def on_slim_text(type, content)
      [:slim, :text, type, compile(content)]
    end

    # Pass-through handler
    def on_slim_embedded(type, content, attrs)
      [:slim, :embedded, type, compile(content), attrs]
    end

    # Pass-through handler
    def on_slim_control(code, content)
      [:slim, :control, code, compile(content)]
    end

    # Pass-through handler
    def on_slim_output(escape, code, content)
      [:slim, :output, escape, code, compile(content)]
    end
  end
end
