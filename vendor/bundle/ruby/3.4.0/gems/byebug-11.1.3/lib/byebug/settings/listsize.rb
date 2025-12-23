# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to customize the number of source code lines to be displayed every
  # time the "list" command is invoked.
  #
  class ListsizeSetting < Setting
    DEFAULT = 10

    def banner
      "Set number of source lines to list by default"
    end

    def to_s
      "Number of source lines to list is #{value}\n"
    end
  end
end
