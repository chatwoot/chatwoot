# coding: utf-8

require "forwardable"

class HighLine
  # Renders an erb template taking a {Question} and a {HighLine} instance
  # as context.
  class TemplateRenderer
    extend Forwardable

    def_delegators :@highline, :color, :list, :key
    def_delegators :@source, :answer_type, :prompt, :header, :answer

    # @return [ERB] ERB template being rendered
    attr_reader :template

    # @return [Question, Menu] Question instance used as context
    attr_reader :source

    # @return [HighLine] HighLine instance used as context
    attr_reader :highline

    # Initializes the TemplateRenderer object with its template and
    # HighLine and Question contexts.
    #
    # @param template [ERB] ERB template.
    # @param source [Question] question object.
    # @param highline [HighLine] HighLine instance.

    def initialize(template, source, highline)
      @template = template
      @source   = source
      @highline = highline
    end

    # @return [String] rendered template
    def render
      template.result(binding)
    end

    # Returns an error message when the called method
    # is not available.
    # @return [String] error message.
    def method_missing(method, *args)
      "Method #{method} with args #{args.inspect} " \
        "is not available on #{inspect}. " \
        "Try #{methods(false).sort.inspect}"
    end

    # @return [Question, Menu] {#source} attribute.
    def menu
      source
    end

    # If some constant is missing at this TemplateRenderer instance,
    # get it from HighLine. Useful to get color and style contants.
    # @param name [Symbol] automatically passed constant's name as Symbol
    def self.const_missing(name)
      HighLine.const_get(name)
    end
  end
end
