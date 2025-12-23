# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Allows the user to continue execution until the next breakpoint, as
  # long as it is different from the current one
  #
  class SkipCommand < Command
    include Helpers::ParseHelper

    class << self
      attr_writer :file_line, :file_path
      attr_reader :previous_autolist

      def file_line
        @file_line ||= 0
      end

      def file_path
        @file_path ||= ""
      end

      def setup_autolist(value)
        @previous_autolist = ListCommand.always_run
        ListCommand.always_run = value
      end

      def restore_autolist
        ListCommand.always_run = @previous_autolist
        @previous_autolist = nil
      end
    end

    def self.regexp
      /^\s* sk(?:ip)? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        sk[ip]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Runs until the next breakpoint as long as it is different from the current one"
    end

    def initialize_attributes
      self.class.always_run = 2
      self.class.setup_autolist(0)
      self.class.file_path = frame.file
      self.class.file_line = frame.line
    end

    def keep_execution
      [self.class.file_path, self.class.file_line] == [frame.file, frame.line]
    end

    def reset_attributes
      self.class.always_run = 0
      ListCommand.new(processor).execute if self.class.previous_autolist == 1
      self.class.restore_autolist
    end

    def auto_run
      return false unless self.class.always_run == 2

      keep_execution ? processor.proceed! : reset_attributes
      true
    end

    def execute
      return if auto_run

      initialize_attributes
      processor.proceed!
      Byebug.stop if Byebug.stoppable?
    end
  end
end
