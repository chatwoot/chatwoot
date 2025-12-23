# frozen_string_literal: true

module Byebug
  #
  # Interface class for standard byebug use.
  #
  class LocalInterface < Interface
    EOF_ALIAS = "continue"

    def initialize
      super()
      @input = $stdin
      @output = $stdout
      @error = $stderr
    end

    #
    # Reads a single line of input using Readline. If Ctrl-D is pressed, it
    # returns "continue", meaning that program's execution will go on.
    #
    # @param prompt Prompt to be displayed.
    #
    def readline(prompt)
      with_repl_like_sigint { without_readline_completion { Readline.readline(prompt) || EOF_ALIAS } }
    end

    #
    # Yields the block handling Ctrl-C the following way: if pressed while
    # waiting for input, the line is reset to only the prompt and we ask for
    # input again.
    #
    # @note Any external 'INT' traps are overriden during this method.
    #
    def with_repl_like_sigint
      orig_handler = trap("INT") { raise Interrupt }
      yield
    rescue Interrupt
      puts("^C")
      retry
    ensure
      trap("INT", orig_handler)
    end

    #
    # Disable any Readline completion procs.
    #
    # Other gems, for example, IRB could've installed completion procs that are
    # dependent on them being loaded. Disable those while byebug is the REPL
    # making use of Readline.
    #
    def without_readline_completion
      orig_completion = Readline.completion_proc
      return yield unless orig_completion

      begin
        Readline.completion_proc = ->(_) { nil }
        yield
      ensure
        Readline.completion_proc = orig_completion
      end
    end
  end
end
