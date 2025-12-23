# frozen_string_literal: true
require_relative 'template'
require 'livescript'

# LiveScript template implementation. See:
# http://livescript.net/
#
# LiveScript templates do not support object scopes, locals, or yield.
Tilt::LiveScriptTemplate = Tilt::StaticTemplate.subclass(mime_type: 'application/javascript') do
  LiveScript.compile(@data, @options)
end
