# frozen_string_literal: true

module Parser
  ##
  # @api private
  #
  module Deprecation
    attr_writer :warned_of_deprecation
    def warn_of_deprecation
      @warned_of_deprecation ||= warn(self::DEPRECATION_WARNING) || true
    end
  end
end
