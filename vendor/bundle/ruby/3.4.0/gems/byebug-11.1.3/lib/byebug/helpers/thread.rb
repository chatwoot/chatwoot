# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Utilities for thread subcommands
    #
    module ThreadHelper
      def display_context(ctx)
        puts pr("thread.context", thread_arguments(ctx))
      end

      def thread_arguments(ctx)
        {
          status_flag: status_flag(ctx),
          debug_flag: debug_flag(ctx),
          id: ctx.thnum,
          thread: ctx.thread.inspect,
          file_line: location(ctx),
          pid: Process.pid,
          status: ctx.thread.status,
          current: current_thread?(ctx)
        }
      end

      def current_thread?(ctx)
        ctx.thread == Thread.current
      end

      def context_from_thread(thnum)
        ctx = Byebug.contexts.find { |c| c.thnum.to_s == thnum }

        err = if ctx.nil?
                pr("thread.errors.no_thread")
              elsif ctx == context
                pr("thread.errors.current_thread")
              elsif ctx.ignored?
                pr("thread.errors.ignored", arg: thnum)
              end

        [ctx, err]
      end

      private

      # @todo Check whether it is Byebug.current_context or context
      def location(ctx)
        return context.location if ctx == Byebug.current_context

        backtrace = ctx.thread.backtrace_locations
        return "" unless backtrace && backtrace[0]

        "#{backtrace[0].path}:#{backtrace[0].lineno}"
      end

      def status_flag(ctx)
        return "$" if ctx.suspended?

        current_thread?(ctx) ? "+" : " "
      end

      def debug_flag(ctx)
        ctx.ignored? ? "!" : " "
      end
    end
  end
end
