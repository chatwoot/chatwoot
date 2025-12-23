# frozen_string_literal: true

require_relative "debug"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Info < DebugCommand
      def self.transform_args(args)
        args&.dump
      end

      def execute(*args)
        super(pre_cmds: ["info", *args].join(" "))
      end
    end
  end

  # :startdoc:
end
