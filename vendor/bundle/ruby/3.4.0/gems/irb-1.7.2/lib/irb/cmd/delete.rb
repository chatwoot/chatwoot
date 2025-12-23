# frozen_string_literal: true

require_relative "debug"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Delete < DebugCommand
      def execute(*args)
        super(pre_cmds: ["delete", *args].join(" "))
      end
    end
  end

  # :startdoc:
end
