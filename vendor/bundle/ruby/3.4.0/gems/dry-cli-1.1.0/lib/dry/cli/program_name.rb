# frozen_string_literal: true

module Dry
  class CLI
    # Program name
    #
    # @since 0.1.0
    # @api private
    module ProgramName
      # @since 0.1.0
      # @api private
      SEPARATOR = " "

      # @since 0.1.0
      # @api private
      def self.call(names = [], program_name: $PROGRAM_NAME)
        [File.basename(program_name), names].flatten.join(SEPARATOR)
      end
    end
  end
end
