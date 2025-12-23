# frozen_string_literal: true

class Pry
  # @api private
  # @since v0.13.0
  module Warning
    # Prints a warning message with exact file and line location, similar to how
    # Ruby's -W prints warnings.
    #
    # @param [String] message
    # @return [void]
    def self.warn(message)
      location = caller_locations(2..2).first
      path = location.path
      lineno = location.lineno

      Kernel.warn("#{path}:#{lineno}: warning: #{message}")
    end
  end
end
