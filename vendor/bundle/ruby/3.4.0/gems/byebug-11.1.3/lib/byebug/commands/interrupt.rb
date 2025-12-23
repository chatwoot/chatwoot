# frozen_string_literal: true

require_relative "../command"

module Byebug
  #
  # Interrupting execution of current thread.
  #
  class InterruptCommand < Command
    self.allow_in_control = true

    def self.regexp
      /^\s*int(?:errupt)?\s*$/
    end

    def self.description
      <<-DESCRIPTION
        int[errupt]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Interrupts the program"
    end

    def execute
      Byebug.start

      Byebug.thread_context(Thread.main).interrupt
    end
  end
end
