# frozen_string_literal: true

require_relative "debug"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Step < DebugCommand
      def execute(*args)
        super(do_cmds: ["step", *args].join(" "))
      end
    end
  end

  # :startdoc:
end
