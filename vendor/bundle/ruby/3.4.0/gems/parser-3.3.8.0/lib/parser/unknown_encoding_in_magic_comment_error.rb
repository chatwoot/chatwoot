# frozen_string_literal: true

module Parser
  ##
  # {Parser::UnknownEncodingInMagicComment} is raised when a magic encoding
  # comment is encountered that the currently running Ruby version doesn't
  # recognize. It inherits from {ArgumentError} since that is the exception
  # Ruby itself raises when trying to execute a file with an unknown encoding.
  # As such, it is also not a {Parser::SyntaxError}.
  #
  # @api public
  #
  class UnknownEncodingInMagicComment < ArgumentError
  end
end
