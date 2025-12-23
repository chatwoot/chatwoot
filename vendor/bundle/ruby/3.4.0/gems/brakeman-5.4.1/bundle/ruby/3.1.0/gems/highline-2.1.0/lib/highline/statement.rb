# coding: utf-8

require "highline/wrapper"
require "highline/paginator"
require "highline/template_renderer"

class HighLine
  # This class handles proper formatting based
  # on a HighLine context, applying wrapping,
  # pagination, indentation and color rendering
  # when necessary. It's used by {HighLine#render_statement}
  # @see HighLine#render_statement
  class Statement
    # The source object to be stringfied and formatted.
    attr_reader :source

    # The HighLine context
    # @return [HighLine]
    attr_reader :highline

    # The stringfied source object
    # @return [String]
    attr_reader :template_string

    # It needs the input String and the HighLine context
    # @param source [#to_s]
    # @param highline [HighLine] context
    def initialize(source, highline)
      @highline = highline
      @source   = source
      @template_string = stringfy(source)
    end

    # Returns the formated statement.
    # Applies wrapping, pagination, indentation and color rendering
    # based on HighLine instance settings.
    # @return [String] formated statement
    def statement
      @statement ||= format_statement
    end

    # (see #statement)
    # Delegates to {#statement}
    def to_s
      statement
    end

    def self.const_missing(constant)
      HighLine.const_get(constant)
    end

    private

    def stringfy(template_string)
      String(template_string || "").dup
    end

    def format_statement
      return template_string if template_string.empty?

      statement = render_template

      statement = HighLine::Wrapper.wrap(statement, highline.wrap_at)
      statement = HighLine::Paginator.new(highline).page_print(statement)

      statement = statement.gsub(/\n(?!$)/, "\n#{highline.indentation}") if
        highline.multi_indent

      statement
    end

    def render_template
      # Assigning to a local var so it may be
      # used inside instance eval block

      template_renderer = TemplateRenderer.new(template, source, highline)
      template_renderer.render
    end

    def template
      @template ||= if ERB.instance_method(:initialize).parameters.assoc(:key) # Ruby 2.6+
        ERB.new(template_string, trim_mode: "%")
      else
        ERB.new(template_string, nil, "%")
      end
    end
  end
end
