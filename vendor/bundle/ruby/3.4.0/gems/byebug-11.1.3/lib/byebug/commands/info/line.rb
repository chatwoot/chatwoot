# frozen_string_literal: true

module Byebug
  #
  # Reopens the +info+ command to define the +line+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about current location
    #
    class LineCommand < Command
      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* l(?:ine)? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          inf[o] l[ine]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Line number and file name of current position in source file."
      end

      def execute
        puts "Line #{frame.line} of \"#{frame.file}\""
      end
    end
  end
end
