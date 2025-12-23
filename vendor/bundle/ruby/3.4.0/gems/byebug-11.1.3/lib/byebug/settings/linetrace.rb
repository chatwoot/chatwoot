# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to enable/disable linetracing.
  #
  class LinetraceSetting < Setting
    def banner
      "Enable line execution tracing"
    end

    def value=(val)
      Byebug.tracing = val
    end

    def value
      Byebug.tracing?
    end
  end
end
