class Thor
  module Shell
    class Basic
      #
      # Prints an error message to `stderr`.
      #
      # @param [String] message
      #   The message to print to `stderr`.
      #
      # @param [Symbol, nil] color
      #   Optional ANSI color.
      #
      # @param [Boolean] force_new_line
      #   Controls whether a newline character will be appended to the output.
      #
      def say_error(message,color=nil,force_new_line=(message.to_s !~ /( |\t)\Z/))
        return if quiet?

        buffer = prepare_message(message,*color)
        buffer << $/ if force_new_line && !message.to_s.end_with?($/)

        stderr.print(buffer)
        stderr.flush
      end
    end

    module_eval <<-METHOD, __FILE__, __LINE__ + 1
      def say_error(*args,&block)
        shell.say_error(*args,&block)
      end
    METHOD
  end
end
