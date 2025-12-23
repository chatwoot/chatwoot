# frozen_string_literal: true
require_relative 'template'
require 'typescript-node'

Tilt::TypeScriptTemplate = Tilt::StaticTemplate.subclass(mime_type: 'application/javascript') do
  option_args = []

  @options.each do |key, value|
    next unless value

    option_args << "--#{key}"

    if value != true
      option_args << value.to_s
    end
  end

  TypeScript::Node.compile(@data, *option_args)
end
