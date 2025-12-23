# frozen_string_literal: true

require_relative "debug"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Backtrace < DebugCommand
      def self.transform_args(args)
        args&.dump
      end

      def execute(*args)
        super(pre_cmds: ["backtrace", *args].join(" "))
      end
    end
  end

  # :startdoc:
end
