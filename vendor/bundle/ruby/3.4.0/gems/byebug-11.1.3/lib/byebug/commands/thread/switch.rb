# frozen_string_literal: true

require_relative "../../helpers/thread"

module Byebug
  #
  # Reopens the +thread+ command to define the +switch+ subcommand
  #
  class ThreadCommand < Command
    #
    # Switches to the specified thread
    #
    class SwitchCommand < Command
      include Helpers::ThreadHelper

      def self.regexp
        /^\s* sw(?:itch)? (?: \s* (\d+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          th[read] sw[itch] <thnum>

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Switches execution to the specified thread"
      end

      def execute
        return puts(help) unless @match[1]

        context, err = context_from_thread(@match[1])
        return errmsg(err) if err

        display_context(context)

        context.switch

        processor.proceed!
      end
    end
  end
end
