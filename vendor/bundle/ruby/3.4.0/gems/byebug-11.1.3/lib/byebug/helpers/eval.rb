# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Utilities to assist evaluation of code strings
    #
    module EvalHelper
      #
      # Evaluates an +expression+ in a separate thread.
      #
      # @param expression [String] Expression to evaluate
      #
      def separate_thread_eval(expression)
        allowing_other_threads do
          in_new_thread { warning_eval(expression) }
        end
      end

      #
      # Evaluates an +expression+ that might use or defer execution to threads
      # other than the current one.
      #
      # @note This is necessary because when in byebug's prompt, every thread is
      # "frozen" so that nothing gets run. So we need to unlock threads prior
      # to evaluation or we will run into a deadlock.
      #
      # @param expression [String] Expression to evaluate
      #
      def multiple_thread_eval(expression)
        allowing_other_threads { warning_eval(expression) }
      end

      #
      # Evaluates a string containing Ruby code in a specific binding,
      # returning nil in an error happens.
      #
      def silent_eval(str, binding = frame._binding)
        safe_eval(str, binding) { |_e| nil }
      end

      #
      # Evaluates a string containing Ruby code in a specific binding,
      # handling the errors at an error level.
      #
      def error_eval(str, binding = frame._binding)
        safe_eval(str, binding) { |e| raise(e, msg(e)) }
      end

      #
      # Evaluates a string containing Ruby code in a specific binding,
      # handling the errors at a warning level.
      #
      def warning_eval(str, binding = frame._binding)
        safe_eval(str, binding) { |e| errmsg(msg(e)) }
      end

      private

      def safe_eval(str, binding)
        binding.eval(str.gsub(/\Aeval /, ""), "(byebug)", 1)
      rescue StandardError, ScriptError => e
        yield(e)
      end

      def msg(exception)
        msg = Setting[:stack_on_error] ? error_msg(exception) : warning_msg(exception)

        pr("eval.exception", text_message: msg)
      end

      def error_msg(exception)
        at = exception.backtrace

        locations = ["#{at.shift}: #{warning_msg(exception)}"]
        locations += at.map { |path| "  from #{path}" }
        locations.join("\n")
      end

      def warning_msg(exception)
        "#{exception.class} Exception: #{exception.message}"
      end

      #
      # Run block temporarily ignoring all TracePoint events.
      #
      # Used to evaluate stuff within Byebug's prompt. Otherwise, any code
      # creating new threads won't be properly evaluated because new threads
      # will get blocked by byebug's main thread.
      #
      def allowing_other_threads
        Byebug.unlock

        res = yield

        Byebug.lock

        res
      end

      #
      # Runs the given block in a new thread, waits for it to finish and
      # returns the new thread's result.
      #
      def in_new_thread
        res = nil

        Thread.new { res = yield }.join

        res
      end

      def safe_inspect(var)
        var.inspect
      rescue StandardError
        safe_to_s(var)
      end

      def safe_to_s(var)
        var.to_s
      rescue StandardError
        "*Error in evaluation*"
      end
    end
  end
end
