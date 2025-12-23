# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to customize the file where byebug's history is saved.
  #
  class HistfileSetting < Setting
    DEFAULT = File.expand_path(".byebug_history")

    def banner
      "File where cmd history is saved to. Default: ./.byebug_history"
    end

    def to_s
      "The command history file is #{value}\n"
    end
  end
end
