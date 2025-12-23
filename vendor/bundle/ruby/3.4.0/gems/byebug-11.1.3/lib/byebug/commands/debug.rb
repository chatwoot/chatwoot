# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/eval"

module Byebug
  #
  # Spawns a subdebugger and evaluates the given expression
  #
  class DebugCommand < Command
    include Helpers::EvalHelper

    def self.regexp
      /^\s* debug (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        debug <expression>

        #{short_description}

        Allows, for example, setting breakpoints on expressions evaluated from
        the debugger's prompt.
      DESCRIPTION
    end

    def self.short_description
      "Spawns a subdebugger"
    end

    def execute
      return puts(help) unless @match[1]

      puts safe_inspect(separate_thread_eval(@match[1]))
    end
  end
end
