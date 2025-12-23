# frozen_string_literal: true

require_relative "show_doc"

module IRB
  module ExtendCommand
    class Help < ShowDoc
      category "Context"
      description "[DEPRECATED] Enter the mode to look up RI documents."

      DEPRECATION_MESSAGE = <<~MSG
        [Deprecation] The `help` command will be repurposed to display command help in the future.
        For RI document lookup, please use the `show_doc` command instead.
        For command help, please use `show_cmds` for now.
      MSG

      def execute(*names)
        warn DEPRECATION_MESSAGE
        super
      end
    end
  end
end
