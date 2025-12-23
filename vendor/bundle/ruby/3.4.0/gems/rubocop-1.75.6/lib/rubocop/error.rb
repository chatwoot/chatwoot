# frozen_string_literal: true

module RuboCop
  # An Error exception is different from an Offense with severity 'error'
  # When this exception is raised, it means that RuboCop is unable to perform
  # a requested action (probably due to misconfiguration) and must stop
  # immediately, rather than carrying on
  class Error < StandardError; end

  class ValidationError < Error; end

  # A wrapper to display errored location of analyzed file.
  class ErrorWithAnalyzedFileLocation < Error
    def initialize(cause:, node:, cop:)
      super()
      @cause = cause
      @cop = cop
      @location = node.is_a?(RuboCop::AST::Node) ? node.loc : node
    end

    attr_reader :cause, :cop

    def line
      @location&.line
    end

    def column
      @location&.column
    end

    def message
      "cause: #{cause.inspect}"
    end
  end
end
