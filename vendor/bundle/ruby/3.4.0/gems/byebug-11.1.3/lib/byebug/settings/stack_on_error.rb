# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to enable/disable the display of backtraces when evaluations raise
  # errors.
  #
  class StackOnErrorSetting < Setting
    def banner
      "Display stack trace when `eval` raises an exception"
    end
  end
end
