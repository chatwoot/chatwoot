# frozen_string_literal: true

module Parser
  ##
  # {Parser::ClobberingError} is raised when {Parser::Source::Rewriter}
  # detects a clobbering rewrite action. This class inherits {RuntimeError}
  # rather than {StandardError} for backward compatibility.
  #
  # @api public
  #
  class ClobberingError < RuntimeError
  end
end
