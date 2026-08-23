# frozen_string_literal: true

module CustomExceptions::Channel
  # Raised when the inbox creation endpoint receives a param_type with no
  # matching (or createable) channel class.
  class Unsupported < CustomExceptions::Base
    def initialize(param_type = nil)
      super
      @param_type = param_type
    end

    def message
      "Channel type is not supported: #{@param_type}"
    end
  end
end
