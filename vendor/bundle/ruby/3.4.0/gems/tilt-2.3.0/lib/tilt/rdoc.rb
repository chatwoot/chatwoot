# frozen_string_literal: true
require_relative 'template'
require 'rdoc'
require 'rdoc/markup'
require 'rdoc/markup/to_html'
require 'rdoc/options'

# RDoc template. See: https://github.com/ruby/rdoc
#
# It's suggested that your program run the following at load time when
# using this templae engine in a threaded environment:
#
#   require 'rdoc'
#   require 'rdoc/markup'
#   require 'rdoc/markup/to_html'
#   require 'rdoc/options'
Tilt::RDocTemplate = Tilt::StaticTemplate.subclass do
  RDoc::Markup::ToHtml.new(RDoc::Options.new, nil).convert(@data).to_s
end
