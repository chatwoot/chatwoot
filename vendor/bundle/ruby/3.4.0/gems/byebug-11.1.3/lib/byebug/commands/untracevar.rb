# frozen_string_literal: true

require_relative "../command"

module Byebug
  #
  # Stop tracing a global variable.
  #
  class UntracevarCommand < Command
    def self.regexp
      /^\s* untr(?:acevar)? (?:\s+ (\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        untr[acevar] <variable>

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Stops tracing a global variable"
    end

    def execute
      var = @match[1]
      if global_variables.include?(:"#{var}")
        untrace_var(:"#{var}")
        puts pr("trace.messages.undo", var: var)
      else
        errmsg pr("trace.errors.not_global", var: var)
      end
    end
  end
end
