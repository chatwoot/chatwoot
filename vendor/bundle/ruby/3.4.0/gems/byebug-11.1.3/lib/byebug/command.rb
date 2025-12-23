# frozen_string_literal: true

require "forwardable"
require_relative "helpers/string"

module Byebug
  #
  # Parent class of all byebug commands.
  #
  # Subclass it and name the subclass ending with the word Command to implement
  # your own custom command.
  #
  # @example Define a custom command
  #
  # class MyCustomCommand < Command
  #   def self.regexp
  #     /custom_regexp/
  #   end
  #
  #   def self.description
  #     "Custom long desc"
  #   end
  #
  #   def.short_description
  #     "Custom short desc"
  #   end
  #
  #   def execute
  #     # My command's implementation
  #   end
  # end
  #
  class Command
    extend Forwardable

    attr_reader :processor

    def initialize(processor, input = self.class.to_s)
      @processor = processor
      @match = match(input)
    end

    def context
      @context ||= processor.context
    end

    def frame
      @frame ||= context.frame
    end

    def arguments
      @match[0].split(" ").drop(1).join(" ")
    end

    def_delegators "self.class", :help, :match

    def_delegator "processor.printer", :print, :pr
    def_delegator "processor.printer", :print_collection, :prc
    def_delegator "processor.printer", :print_variables, :prv

    def_delegators "processor.interface", :errmsg, :puts, :print, :confirm

    class << self
      include Helpers::StringHelper

      #
      # Special methods to allow command filtering in processors
      #
      attr_accessor :allow_in_control, :allow_in_post_mortem

      attr_writer :always_run

      def always_run
        @always_run ||= 0
      end

      #
      # Name of the command, as executed by the user.
      #
      def to_s
        name
          .split("::")
          .map { |n| n.gsub(/Command$/, "").downcase if /Command$/.match?(n) }
          .compact
          .join(" ")
      end

      def columnize(width)
        format(
          "  %-<name>#{width}s -- %<description>s\n",
          name: to_s,
          description: short_description
        )
      end

      #
      # Default help text for a command.
      #
      def help
        prettify(description)
      end

      #
      # Command's regexp match against an input
      #
      def match(input)
        regexp.match(input)
      end
    end
  end
end
