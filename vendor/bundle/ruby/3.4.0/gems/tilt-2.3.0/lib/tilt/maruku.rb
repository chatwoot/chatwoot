# frozen_string_literal: true
require_relative 'template'
require 'maruku'

# Maruku markdown implementation. See: https://github.com/bhollis/maruku
Tilt::MarukuTemplate = Tilt::StaticTemplate.subclass do
  Maruku.new(@data, @options).to_html
end
