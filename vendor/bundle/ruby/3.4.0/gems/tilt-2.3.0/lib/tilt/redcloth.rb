# frozen_string_literal: true
require_relative 'template'
require 'redcloth'

# RedCloth implementation. See: https://github.com/jgarber/redcloth
Tilt::RedClothTemplate = Tilt::StaticTemplate.subclass do
  engine = RedCloth.new(@data)
  @options.each  do |k, v|
    m = :"#{k}="
    engine.send(m, v) if engine.respond_to? m
  end
  engine.to_html
end
