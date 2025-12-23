# frozen_string_literal: true

class Pry
  # @api private
  # @since v0.13.0
  module SystemCommandHandler
    class << self
      def default(output, command, _pry_instance)
        return if Kernel.system(command)

        output.puts(
          "Error: there was a problem executing system command: #{command}"
        )
      end
    end
  end
end
