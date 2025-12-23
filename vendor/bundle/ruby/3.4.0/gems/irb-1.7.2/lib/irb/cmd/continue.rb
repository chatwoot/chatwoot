# frozen_string_literal: true

require_relative "debug"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Continue < DebugCommand
      def execute(*args)
        super(do_cmds: ["continue", *args].join(" "))
      end
    end
  end

  # :startdoc:
end
