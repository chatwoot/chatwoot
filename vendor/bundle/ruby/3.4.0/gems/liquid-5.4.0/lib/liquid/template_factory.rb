# frozen_string_literal: true

module Liquid
  class TemplateFactory
    def for(_template_name)
      Liquid::Template.new
    end
  end
end
