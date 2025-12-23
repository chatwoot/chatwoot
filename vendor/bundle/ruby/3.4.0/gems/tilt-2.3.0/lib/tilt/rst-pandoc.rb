# frozen_string_literal: true
require_relative 'template'
require_relative 'pandoc'

rst = {:f => "rst"}.freeze

# Pandoc reStructuredText implementation. See: # http://pandoc.org/
Tilt::RstPandocTemplate = Tilt::StaticTemplate.subclass do
  PandocRuby.new(@data, rst).to_html.strip
end
