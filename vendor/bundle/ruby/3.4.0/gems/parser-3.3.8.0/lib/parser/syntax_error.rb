# frozen_string_literal: true

module Parser
  ##
  # {Parser::SyntaxError} is raised whenever parser detects a syntax error,
  # similar to the standard SyntaxError class.
  #
  # @api public
  #
  # @!attribute [r] diagnostic
  #  @return [Parser::Diagnostic]
  #
  class SyntaxError < StandardError
    attr_reader :diagnostic

    def initialize(diagnostic)
      @diagnostic = diagnostic
      super(diagnostic.message)
    end
  end
end
