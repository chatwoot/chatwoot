# frozen_string_literal: true

require_relative "../setting"
require_relative "../commands/pry"

module Byebug
  #
  # Setting for automatically invoking Pry on every stop.
  #
  class AutoprySetting < Setting
    DEFAULT = 0

    def initialize
      PryCommand.always_run = DEFAULT
    end

    def banner
      "Invoke Pry on every stop"
    end

    def value=(val)
      PryCommand.always_run = val ? 1 : 0
    end

    def value
      PryCommand.always_run == 1
    end
  end
end
