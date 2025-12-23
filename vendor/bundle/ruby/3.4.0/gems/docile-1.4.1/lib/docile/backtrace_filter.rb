# frozen_string_literal: true

module Docile
  # @api private
  #
  # This is used to remove entries pointing to Docile's source files
  # from {Exception#backtrace} and {Exception#backtrace_locations}.
  #
  # If {NoMethodError} is caught then the exception object will be extended
  # by this module to add filter functionalities.
  module BacktraceFilter
    FILTER_PATTERN = %r{/lib/docile/}.freeze

    def backtrace
      super.grep_v(FILTER_PATTERN)
    end

    if ::Exception.public_method_defined?(:backtrace_locations)
      def backtrace_locations
        super.reject { |location| location.absolute_path =~ FILTER_PATTERN }
      end
    end
  end
end
