# frozen_string_literal: true

require_relative "../command"

module Byebug
  #
  # Show (and possibily stop) at every line that changes a global variable.
  #
  class TracevarCommand < Command
    def self.regexp
      /^\s* tr(?:acevar)? (?: \s+ (\S+))?  # (variable-name)?
                          (?: \s+ (stop|nostop))?
       \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        tr[acevar] <variable> [[no]stop]

        #{short_description}

        If "stop" is specified, execution will stop every time the variable
        changes its value. If nothing or "nostop" is specified, execution won't
        stop, changes will just be logged in byebug's output.
      DESCRIPTION
    end

    def self.short_description
      "Enables tracing of a global variable"
    end

    def execute
      var = @match[1]
      return errmsg(pr("trace.errors.needs_global_variable")) unless var
      return errmsg(pr("trace.errors.var_is_not_global", name: var)) unless global_variables.include?(:"#{var}")

      stop = @match[2] && @match[2] !~ /nostop/

      instance_eval do
        trace_var(:"#{var}") { |val| on_change(var, val, stop) }
      end

      puts pr("trace.messages.success", var: var)
    end

    private

    def on_change(name, value, stop)
      puts pr("trace.messages.on_change", name: name, value: value)

      context.step_out(1, false) if stop
    end
  end
end
