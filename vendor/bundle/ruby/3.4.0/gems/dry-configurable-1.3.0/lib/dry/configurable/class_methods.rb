# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    module ClassMethods
      include Methods

      # @api private
      def inherited(subclass)
        super

        subclass.instance_variable_set(:@__config_extension__, __config_extension__)

        new_settings = settings.dup
        subclass.instance_variable_set(:@__settings__, new_settings)

        # Only classes **extending** Dry::Configurable have class-level config. When
        # Dry::Configurable is **included**, the class-level config method is undefined because it
        # resides at the instance-level instead (see `Configurable.included`).
        if respond_to?(:config)
          subclass.instance_variable_set(:@__config__, config.dup_for_settings(new_settings))
        end
      end

      # Add a setting to the configuration
      #
      # @param [Mixed] name
      #   The accessor key for the configuration value
      # @param [Mixed] default
      #   Default value for the setting
      # @param [#call] constructor
      #   Transformation given value will go through
      # @param [Boolean] reader
      #   Whether a reader accessor must be created
      # @yield
      #   A block can be given to add nested settings.
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def setting(...)
        setting = __config_dsl__.setting(...)

        settings << setting

        __config_reader__.define(setting.name) if setting.reader?

        self
      end

      # Returns the defined settings for the class.
      #
      # @return [Settings]
      #
      # @api public
      def settings
        @__settings__ ||= Settings.new
      end

      # Return configuration
      #
      # @return [Config]
      #
      # @api public
      def config
        @__config__ ||= __config_build__
      end

      # @api private
      def __config_build__(settings = self.settings)
        __config_extension__.config_class.new(settings)
      end

      # @api private
      def __config_extension__
        @__config_extension__
      end

      # @api private
      def __config_dsl__
        @__config_dsl__ ||= DSL.new(
          config_class: __config_extension__.config_class,
          default_undefined: __config_extension__.default_undefined
        )
      end

      # @api private
      def __config_reader__
        @__config_reader__ ||=
          begin
            reader = Module.new do
              def self.define(name)
                define_method(name) do
                  config[name]
                end
              end
            end

            if included_modules.include?(InstanceMethods)
              include(reader)
            end

            extend(reader)

            reader
          end
      end
    end
  end
end
