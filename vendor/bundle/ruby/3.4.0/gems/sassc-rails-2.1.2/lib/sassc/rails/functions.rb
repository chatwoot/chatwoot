# frozen_string_literal: true

require 'sprockets/sass_functions'

module Sprockets
  module SassFunctions
    def asset_data_url(path)
      ::SassC::Script::Value::String.new("url(" + sprockets_context.asset_data_uri(path.value) + ")")
    end
  end
end

::SassC::Script::Functions.send :include, Sprockets::SassFunctions
