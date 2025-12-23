# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to customize the number of byebug commands to be saved in history.
  #
  class HistsizeSetting < Setting
    DEFAULT = 256

    def banner
      "Maximum number of commands that can be stored in byebug history"
    end

    def to_s
      "Maximum size of byebug's command history is #{value}"
    end
  end
end
