# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Command to display short paths in file names.
  #
  # For example, when displaying source code information.
  #
  class BasenameSetting < Setting
    def banner
      "<file>:<line> information after every stop uses short paths"
    end
  end
end
