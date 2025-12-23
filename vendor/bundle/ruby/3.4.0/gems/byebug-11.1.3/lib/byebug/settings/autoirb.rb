# frozen_string_literal: true

require_relative "../setting"
require_relative "../commands/irb"

module Byebug
  #
  # Setting for automatically invoking IRB on every stop.
  #
  class AutoirbSetting < Setting
    DEFAULT = 0

    def initialize
      IrbCommand.always_run = DEFAULT
    end

    def banner
      "Invoke IRB on every stop"
    end

    def value=(val)
      IrbCommand.always_run = val ? 1 : 0
    end

    def value
      IrbCommand.always_run == 1
    end
  end
end
