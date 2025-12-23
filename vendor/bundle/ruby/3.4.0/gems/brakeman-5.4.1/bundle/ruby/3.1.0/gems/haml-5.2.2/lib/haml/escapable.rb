# frozen_string_literal: true

module Haml
  # Like Temple::Filters::Escapable, but with support for escaping by
  # Haml::Herlpers.html_escape and Haml::Herlpers.escape_once.
  class Escapable < Temple::Filter
    # Special value of `flag` to ignore html_safe?
    EscapeSafeBuffer = Struct.new(:value)

    def initialize(*)
      super
      @escape = false
      @escape_safe_buffer = false
    end

    def on_escape(flag, exp)
      old_escape, old_escape_safe_buffer = @escape, @escape_safe_buffer
      @escape_safe_buffer = flag.is_a?(EscapeSafeBuffer)
      @escape = @escape_safe_buffer ? flag.value : flag
      compile(exp)
    ensure
      @escape, @escape_safe_buffer = old_escape, old_escape_safe_buffer
    end

    # The same as Haml::AttributeBuilder.build_attributes
    def on_static(value)
      [:static,
       if @escape == :once
         escape_once(value)
       elsif @escape
         escape(value)
       else
         value
       end
      ]
    end

    # The same as Haml::AttributeBuilder.build_attributes
    def on_dynamic(value)
      [:dynamic,
       if @escape == :once
         escape_once_code(value)
       elsif @escape
         escape_code(value)
       else
         "(#{value}).to_s"
       end
      ]
    end

    private

    def escape_once(value)
      if @escape_safe_buffer
        ::Haml::Helpers.escape_once_without_haml_xss(value)
      else
        ::Haml::Helpers.escape_once(value)
      end
    end

    def escape(value)
      if @escape_safe_buffer
        ::Haml::Helpers.html_escape_without_haml_xss(value)
      else
        ::Haml::Helpers.html_escape(value)
      end
    end

    def escape_once_code(value)
      "::Haml::Helpers.escape_once#{('_without_haml_xss' if @escape_safe_buffer)}((#{value}))"
    end

    def escape_code(value)
      "::Haml::Helpers.html_escape#{('_without_haml_xss' if @escape_safe_buffer)}((#{value}))"
    end
  end
end
