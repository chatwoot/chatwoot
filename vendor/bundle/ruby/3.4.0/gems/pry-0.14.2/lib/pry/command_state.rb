# frozen_string_literal: true

require 'ostruct'

class Pry
  # CommandState is a data structure to hold per-command state.
  #
  # Pry commands can store arbitrary state here. This state persists between
  # subsequent command invocations. All state saved here is unique to the
  # command.
  #
  # @since v0.13.0
  # @api private
  class CommandState
    def self.default
      @default ||= new
    end

    def initialize
      @command_state = {}
    end

    def state_for(command_name)
      @command_state[command_name] ||= OpenStruct.new
    end

    def reset(command_name)
      @command_state[command_name] = OpenStruct.new
    end
  end
end
