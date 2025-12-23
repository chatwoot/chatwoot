# frozen_string_literal: true

require "pathname"

module SassC

  class BaseError < StandardError; end
  class NotRenderedError < BaseError; end
  class InvalidStyleError < BaseError; end
  class UnsupportedValue < BaseError; end

  # When dealing with SyntaxErrors,
  # it's important to provide filename and line number information.
  # This will be used in various error reports to users, including backtraces.

  class SyntaxError < BaseError

    def initialize(message, filename: nil, line: nil)
      @filename = filename
      @line = line
      super(message)
    end

    def backtrace
      return nil if super.nil?
      sass_backtrace + super
    end

    # The backtrace of the error within Sass files.
    def sass_backtrace
      return [] unless @filename && @line
      ["#{@filename}:#{@line}"]
    end

  end

end
