# frozen_string_literal: true

require_relative "helpers/string"

module Byebug
  #
  # Parent class for all byebug settings.
  #
  class Setting
    attr_accessor :value

    DEFAULT = false

    def initialize
      @value = self.class::DEFAULT
    end

    def boolean?
      [true, false].include?(value)
    end

    def integer?
      Integer(value) ? true : false
    rescue ArgumentError
      false
    end

    def help
      prettify(banner)
    end

    def to_sym
      name = self.class.name.gsub(/^Byebug::/, "").gsub(/Setting$/, "")
      name.gsub(/(.)([A-Z])/, '\1_\2').downcase.to_sym
    end

    def to_s
      "#{to_sym} is #{value ? 'on' : 'off'}\n"
    end

    class << self
      def settings
        @settings ||= {}
      end

      def [](name)
        settings[name].value
      end

      def []=(name, value)
        settings[name].value = value
      end

      def find(shortcut)
        abbr = /^no/.match?(shortcut) ? shortcut[2..-1] : shortcut
        matches = settings.select do |key, value|
          key =~ (value.boolean? ? /#{abbr}/ : /#{shortcut}/)
        end
        matches.size == 1 ? matches.values.first : nil
      end

      #
      # @todo DRY this up. Very similar code exists in the CommandList class
      #
      def help_all
        output = "  List of supported settings:\n\n"
        width = settings.keys.max_by(&:size).size
        settings.each_value do |sett|
          output += format(
            "  %<name>-#{width}s -- %<description>s\n",
            name: sett.to_sym,
            description: sett.banner
          )
        end
        output + "\n"
      end
    end
  end
end
