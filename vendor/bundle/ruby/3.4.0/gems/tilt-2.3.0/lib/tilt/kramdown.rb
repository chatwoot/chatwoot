# frozen_string_literal: true
require_relative 'template'
require 'kramdown'

dumb_quotes = [39, 39, 34, 34].freeze

# Kramdown Markdown implementation. See: https://kramdown.gettalong.org/
Tilt::KramdownTemplate = Tilt::StaticTemplate.subclass do
  # dup as Krawmdown modifies the passed option with map!
  @options[:smart_quotes] = dumb_quotes.dup unless @options[:smartypants]

  Kramdown::Document.new(@data, @options).to_html
end
