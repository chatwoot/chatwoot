# frozen_string_literal: true

module Dry
  module Configurable
    # A collection of defined settings on a given class.
    #
    # @api private
    class Settings
      include Dry::Equalizer(:settings)

      include Enumerable

      # @api private
      attr_reader :settings

      # @api private
      def initialize(settings = EMPTY_ARRAY)
        @settings = settings.each_with_object({}) { |s, m| m[s.name] = s }
      end

      # @api private
      private def initialize_copy(source)
        @settings = source.settings.dup
      end

      # @api private
      def <<(setting)
        settings[setting.name] = setting
        self
      end

      # Returns the setting for the given name, if found.
      #
      # @return [Setting, nil] the setting, or nil if not found
      #
      # @api public
      def [](name)
        settings[name]
      end

      # Returns true if a setting for the given name is defined.
      #
      # @return [Boolean]
      #
      # @api public
      def key?(name)
        keys.include?(name)
      end

      # Returns the list of defined setting names.
      #
      # @return [Array<Symbol>]
      #
      # @api public
      def keys
        settings.keys
      end

      # @api public
      def each(&)
        settings.each_value(&)
      end
    end
  end
end
