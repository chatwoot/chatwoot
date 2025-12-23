# frozen_string_literal: true

class Pry
  # @api private
  # @since v0.13.0
  module ExceptionHandler
    class << self
      # Will only show the first line of the backtrace.
      def handle_exception(output, exception, _pry_instance)
        if exception.is_a?(UserError) && exception.is_a?(SyntaxError)
          output.puts "SyntaxError: #{exception.message.sub(/.*syntax error, */m, '')}"
        else
          output.puts standard_error_text_for(exception)
        end
      end

      private

      def standard_error_text_for(exception)
        text = exception_text(exception)
        return text unless exception.respond_to?(:cause)

        cause = exception.cause
        while cause
          text += cause_text(cause)
          cause = cause.cause
        end

        text
      end

      def exception_text(exception)
        "#{exception.class}: #{exception.message}\n" \
        "from #{exception.backtrace.first}\n"
      end

      def cause_text(cause)
        "Caused by #{cause.class}: #{cause}\n" \
        "from #{cause.backtrace.first}\n"
      end
    end
  end
end
