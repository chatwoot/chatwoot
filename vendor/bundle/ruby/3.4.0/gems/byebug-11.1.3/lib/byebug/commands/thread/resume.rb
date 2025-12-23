# frozen_string_literal: true

require_relative "../../helpers/thread"

module Byebug
  #
  # Reopens the +thread+ command to define the +resume+ subcommand
  #
  class ThreadCommand < Command
    #
    # Resumes the specified thread
    #
    class ResumeCommand < Command
      include Helpers::ThreadHelper

      def self.regexp
        /^\s* r(?:esume)? (?: \s* (\d+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          th[read] r[esume] <thnum>

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Resumes execution of the specified thread"
      end

      def execute
        return puts(help) unless @match[1]

        context, err = context_from_thread(@match[1])
        return errmsg(err) if err

        return errmsg(pr("thread.errors.already_running")) unless context.suspended?

        context.resume
        display_context(context)
      end
    end
  end
end
