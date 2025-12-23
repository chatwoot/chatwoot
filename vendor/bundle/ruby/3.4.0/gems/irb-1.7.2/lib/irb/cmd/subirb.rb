# frozen_string_literal: false
#
#   multi.rb -
#   	by Keiju ISHITSUKA(keiju@ruby-lang.org)
#

require_relative "nop"

module IRB
  # :stopdoc:

  module ExtendCommand
    class MultiIRBCommand < Nop
      def initialize(conf)
        super
        extend_irb_context
      end

      private

      def extend_irb_context
        # this extension patches IRB context like IRB.CurrentContext
        require_relative "../ext/multi-irb"
      end
    end

    class IrbCommand < MultiIRBCommand
      category "IRB"
      description "Start a child IRB."

      def execute(*obj)
        IRB.irb(nil, *obj)
      end
    end

    class Jobs < MultiIRBCommand
      category "IRB"
      description "List of current sessions."

      def execute
        IRB.JobManager
      end
    end

    class Foreground < MultiIRBCommand
      category "IRB"
      description "Switches to the session of the given number."

      def execute(key = nil)
        raise CommandArgumentError.new("Please specify the id of target IRB job (listed in the `jobs` command).") unless key
        IRB.JobManager.switch(key)
      end
    end

    class Kill < MultiIRBCommand
      category "IRB"
      description "Kills the session with the given number."

      def execute(*keys)
        IRB.JobManager.kill(*keys)
      end
    end
  end

  # :startdoc:
end
