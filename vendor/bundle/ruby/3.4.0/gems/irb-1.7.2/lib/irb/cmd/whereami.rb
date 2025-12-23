# frozen_string_literal: true

require_relative "nop"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Whereami < Nop
      category "Context"
      description "Show the source code around binding.irb again."

      def execute(*)
        code = irb_context.workspace.code_around_binding
        if code
          puts code
        else
          puts "The current context doesn't have code."
        end
      end
    end
  end

  # :startdoc:
end
