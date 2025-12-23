# frozen_string_literal: true

require_relative "../setting"
require_relative "../commands/list"

module Byebug
  #
  # Setting for automatically listing source code on every stop.
  #
  class AutolistSetting < Setting
    DEFAULT = 1

    def initialize
      ListCommand.always_run = DEFAULT
    end

    def banner
      "Invoke list command on every stop"
    end

    def value=(val)
      ListCommand.always_run = val ? 1 : 0
    end

    def value
      ListCommand.always_run == 1
    end
  end
end
