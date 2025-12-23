# frozen_string_literal: true

require_relative "../../helpers/thread"

module Byebug
  #
  # Reopens the +thread+ command to define the +list+ subcommand
  #
  class ThreadCommand < Command
    #
    # Information about threads
    #
    class ListCommand < Command
      include Helpers::ThreadHelper

      def self.regexp
        /^\s* l(?:ist)? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          th[read] l[ist] <thnum>

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Lists all threads"
      end

      def execute
        contexts = Byebug.contexts.sort_by(&:thnum)

        thread_list = prc("thread.context", contexts) do |context, _|
          thread_arguments(context)
        end

        print(thread_list)
      end
    end
  end
end
