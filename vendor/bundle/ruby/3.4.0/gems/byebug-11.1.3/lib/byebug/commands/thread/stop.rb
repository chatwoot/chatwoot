# frozen_string_literal: true

require_relative "../../helpers/thread"

module Byebug
  #
  # Reopens the +thread+ command to define the +stop+ subcommand
  #
  class ThreadCommand < Command
    #
    # Stops the specified thread
    #
    class StopCommand < Command
      include Helpers::ThreadHelper

      def self.regexp
        /^\s* st(?:op)? (?: \s* (\d+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          th[read] st[op] <thnum>

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Stops the execution of the specified thread"
      end

      def execute
        return puts(help) unless @match[1]

        context, err = context_from_thread(@match[1])
        return errmsg(err) if err

        context.suspend
        display_context(context)
      end
    end
  end
end
