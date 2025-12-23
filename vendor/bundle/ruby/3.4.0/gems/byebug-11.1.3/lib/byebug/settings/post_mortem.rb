# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to enable/disable post_mortem mode, i.e., a debugger prompt after
  # program termination by unhandled exception.
  #
  class PostMortemSetting < Setting
    def initialize
      Byebug.post_mortem = DEFAULT
    end

    def banner
      "Enable/disable post-mortem mode"
    end

    def value=(val)
      Byebug.post_mortem = val
    end

    def value
      Byebug.post_mortem?
    end
  end
end
