# frozen_string_literal: false
#
#   change-ws.rb -
#   	by Keiju ISHITSUKA(keiju@ruby-lang.org)
#

require_relative "nop"
require_relative "../ext/workspaces"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Workspaces < Nop
      category "IRB"
      description "Show workspaces."

      def execute(*obj)
        irb_context.workspaces.collect{|ws| ws.main}
      end
    end

    class PushWorkspace < Workspaces
      category "IRB"
      description "Push an object to the workspace stack."

      def execute(*obj)
        irb_context.push_workspace(*obj)
        super
      end
    end

    class PopWorkspace < Workspaces
      category "IRB"
      description "Pop a workspace from the workspace stack."

      def execute(*obj)
        irb_context.pop_workspace(*obj)
        super
      end
    end
  end

  # :startdoc:
end
