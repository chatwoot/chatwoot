# frozen_string_literal: true

require_relative "debug"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Break < DebugCommand
      def self.transform_args(args)
        args&.dump
      end

      def execute(args = nil)
        super(pre_cmds: "break #{args}")
      end
    end
  end

  # :startdoc:
end
