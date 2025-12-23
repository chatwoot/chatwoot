require_relative 'error'

module Regexp::Syntax
  class SyntaxError < Regexp::Parser::Error; end
end

require_relative 'syntax/token'
require_relative 'syntax/base'
require_relative 'syntax/any'
require_relative 'syntax/version_lookup'
require_relative 'syntax/versions'
