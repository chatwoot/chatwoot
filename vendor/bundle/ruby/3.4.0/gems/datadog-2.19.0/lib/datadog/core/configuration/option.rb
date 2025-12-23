# frozen_string_literal: true

require_relative 'stable_config'
require_relative '../utils/safe_dup'

module Datadog
  module Core
    module Configuration
      # Represents an instance of an integration configuration option
      # @public_api
      class Option
        # @!attribute [r] definition
        #   The definition object that matches this option.
        #   @return [Configuration::OptionDefinition]
        # @!attribute [r] precedence_set
        #   When this option was last set, what was the value precedence used?
        #   @return [Precedence::Value]
        attr_reader :definition, :precedence_set, :resolved_env

        # Option setting precedence.
        module Precedence
          # Represents an Option precedence level.
          # Each precedence has a `numeric` value; higher values means higher precedence.
          # `name` is for inspection purposes only.
          Value = Struct.new(:numeric, :name, :origin) do
            include Comparable

            def <=>(other)
              return nil unless other.is_a?(Value)

              numeric <=> other.numeric
            end
          end

          # Remote configuration provided through the Datadog app.
          REMOTE_CONFIGURATION = Value.new(5, :remote_configuration, 'remote_config').freeze

          # Configuration provided in Ruby code, in this same process
          PROGRAMMATIC = Value.new(4, :programmatic, 'code').freeze

          # Configuration provided by fleet managed stable config
          FLEET_STABLE = Value.new(3, :fleet_stable, 'fleet_stable_config').freeze

          # Configuration provided via environment variable
          ENVIRONMENT = Value.new(2, :environment, 'env_var').freeze

          # Configuration provided by local stable config file
          LOCAL_STABLE = Value.new(1, :local_stable, 'local_stable_config').freeze

          # Configuration that comes from default values
          DEFAULT = Value.new(0, :default, 'default').freeze

          # All precedences, sorted from highest to lowest
          LIST = [REMOTE_CONFIGURATION, PROGRAMMATIC, FLEET_STABLE, ENVIRONMENT, LOCAL_STABLE, DEFAULT].sort.reverse.freeze
        end

        def initialize(definition, context)
          @definition = definition
          @context = context
          @value = nil
          @is_set = false
          @resolved_env = nil

          # One value is stored per precedence, to allow unsetting a higher
          # precedence value and falling back to a lower precedence one.
          @value_per_precedence = Hash.new(UNSET)

          # Lowest precedence, to allow for `#set` to always succeed for a brand new `Option` instance.
          @precedence_set = Precedence::DEFAULT
        end

        # Overrides the current value for this option if the `precedence` is equal or higher than
        # the previously set value.
        # The first call to `#set` will always store the value regardless of precedence.
        #
        # @param value [Object] the new value to be associated with this option
        # @param precedence [Precedence] from what precedence order this new value comes from
        def set(value, precedence: Precedence::PROGRAMMATIC, resolved_env: nil)
          # Is there a higher precedence value set?
          if @precedence_set > precedence
            # This should be uncommon, as higher precedence values tend to
            # happen later in the application lifecycle.
            Datadog.logger.info do
              "Option '#{definition.name}' not changed to '#{value}' (precedence: #{precedence.name}) because the higher " \
                "precedence value '#{@value}' (precedence: #{@precedence_set.name}) was already set."
            end

            # But if it happens, we have to store the lower precedence value `value`
            # because it's possible to revert to it by `#unset`ting
            # the existing, higher-precedence value.
            # Effectively, we always store one value pre precedence.
            @value_per_precedence[precedence] = value

            return @value
          end

          internal_set(value, precedence, resolved_env)
        end

        def unset(precedence)
          @value_per_precedence[precedence] = UNSET

          # If we are unsetting the currently active value, we have to restore
          # a lower precedence one...
          if precedence == @precedence_set
            # Find a lower precedence value that is already set.
            Precedence::LIST.each do |p|
              # DEV: This search can be optimized, but the list is small, and unset is
              # DEV: only called from direct user interaction in the Datadog UI.
              next unless p < precedence

              # Look for value that is set.
              # The hash `@value_per_precedence` has a custom default value of `UNSET`.
              if (value = @value_per_precedence[p]) != UNSET
                internal_set(value, p, nil)
                return nil
              end
            end

            # If no value is left to fall back on, reset this option
            reset
          end

          # ... otherwise, we are either unsetting a higher precedence value that is not
          # yet set, thus there's nothing to do; or we are unsetting a lower precedence
          # value, which also does not change the current value.
        end

        def get
          unless @is_set
            # Ensures that both the default value and the environment value are set.
            # This approach handles scenarios where an environment value is unset
            # by falling back to the default value consistently.
            set_default_value
            set_customer_stable_config_value
            set_env_value
            set_fleet_stable_config_value
          end

          @value
        end

        def reset
          @value = if definition.resetter
            # Don't change @is_set to false; custom resetters are
            # responsible for changing @value back to a good state.
            # Setting @is_set = false would cause a default to be applied.
            context_exec(@value, &definition.resetter)
          else
            @is_set = false
            nil
          end

          # Reset back to the lowest precedence, to allow all `set`s to succeed right after a reset.
          @precedence_set = Precedence::DEFAULT
          # Reset all stored values
          @value_per_precedence = Hash.new(UNSET)
        end

        def default_value
          if definition.default.instance_of?(Proc)
            context_eval(&definition.default)
          else
            definition.default_proc || Core::Utils::SafeDup.frozen_or_dup(definition.default)
          end
        end

        def default_precedence?
          precedence_set == Precedence::DEFAULT
        end

        private

        def coerce_env_variable(value)
          return context_exec(value, &@definition.env_parser) if @definition.env_parser

          case @definition.type
          when :hash
            values = value.split(',') # By default we only want to support comma separated strings

            values.map! do |v|
              v.gsub!(/\A[\s,]*|[\s,]*\Z/, '')

              v.empty? ? nil : v
            end

            values.compact!
            values.each.with_object({}) do |v, hash|
              pair = v.split(':', 2)
              hash[pair[0]] = pair[1]
            end
          when :int
            Integer(value, 10)
          when :float
            Float(value)
          when :array
            values = value.split(',')

            values.map! do |v|
              v.gsub!(/\A[\s,]*|[\s,]*\Z/, '')

              v.empty? ? nil : v
            end

            values.compact!
            values
          when :bool
            string_value = value.strip
            string_value = string_value.downcase
            string_value == 'true' || string_value == '1'
          when :string, NilClass
            value
          else
            raise InvalidDefinitionError,
              "The option #{@definition.name} is using an unsupported type option for env coercion `#{@definition.type}`"
          end
        end

        # For errors caused by illegal option declarations
        class InvalidDefinitionError < StandardError
        end

        def validate_type(value)
          raise_error = false

          valid_type = validate(@definition.type, value)

          unless valid_type
            raise_error = if @definition.type_options[:nilable]
              !value.is_a?(NilClass)
            else
              true
            end
          end

          if raise_error
            error_msg = if @definition.type_options[:nilable]
              "The setting `#{@definition.name}` inside your app's `Datadog.configure` block expects a " \
              "#{@definition.type} or `nil`, but a `#{value.class}` was provided (#{value.inspect})." \
            else
              "The setting `#{@definition.name}` inside your app's `Datadog.configure` block expects a " \
              "#{@definition.type}, but a `#{value.class}` was provided (#{value.inspect})." \
            end

            error_msg = "#{error_msg} Please update your `configure` block. "

            raise ArgumentError, error_msg
          end

          value
        end

        def validate(type, value)
          case type
          when :string
            value.is_a?(String)
          when :int
            value.is_a?(Integer)
          when :float
            value.is_a?(Float) || value.is_a?(Integer) || value.is_a?(Rational)
          when :array
            value.is_a?(Array)
          when :hash
            value.is_a?(Hash)
          when :bool
            value.is_a?(TrueClass) || value.is_a?(FalseClass)
          when :proc
            value.is_a?(Proc)
          when :symbol
            value.is_a?(Symbol)
          when NilClass
            true # No validation is performed when option is typeless
          else
            raise InvalidDefinitionError,
              "The option #{@definition.name} is using an unsupported type option `#{@definition.type}`"
          end
        end

        # Directly manipulates the current value and currently set precedence.
        def internal_set(value, precedence, resolved_env)
          old_value = @value
          (@value = context_exec(validate_type(value), old_value, &definition.setter)).tap do |v|
            @is_set = true
            @precedence_set = precedence
            @resolved_env = resolved_env
            # Store original value to ensure we can always safely call `#internal_set`
            # when restoring a value from `@value_per_precedence`, and we are only running `definition.setter`
            # on the original value, not on a value that has already been processed by `definition.setter`.
            @value_per_precedence[precedence] = value
            context_exec(v, old_value, precedence, &definition.after_set) if definition.after_set
          end
        end

        def context_exec(*args, &block)
          @context.instance_exec(*args, &block)
        end

        def context_eval(&block)
          @context.instance_eval(&block)
        end

        def set_default_value
          set(default_value, precedence: Precedence::DEFAULT)
        end

        def set_env_value
          value, resolved_env = get_value_and_resolved_env_from(ENV)
          set(value, precedence: Precedence::ENVIRONMENT, resolved_env: resolved_env) unless value.nil?
        end

        def set_customer_stable_config_value
          customer_config = StableConfig.configuration.dig(:local, :config)
          return if customer_config.nil?

          value, resolved_env = get_value_and_resolved_env_from(customer_config, source: 'local stable config')
          set(value, precedence: Precedence::LOCAL_STABLE, resolved_env: resolved_env) unless value.nil?
        end

        def set_fleet_stable_config_value
          fleet_config = StableConfig.configuration.dig(:fleet, :config)
          return if fleet_config.nil?

          value, resolved_env = get_value_and_resolved_env_from(fleet_config, source: 'fleet stable config')
          set(value, precedence: Precedence::FLEET_STABLE, resolved_env: resolved_env) unless value.nil?
        end

        def get_value_and_resolved_env_from(env_vars, source: 'environment variable')
          value = nil
          resolved_env = nil

          if definition.env
            Array(definition.env).each do |env|
              next if env_vars[env].nil?

              resolved_env = env
              value = coerce_env_variable(env_vars[env])
              break
            end
          end

          if value.nil? && definition.deprecated_env && env_vars[definition.deprecated_env]
            resolved_env = definition.deprecated_env
            value = coerce_env_variable(env_vars[definition.deprecated_env])

            Datadog::Core.log_deprecation do
              "#{definition.deprecated_env} #{source} is deprecated, use #{definition.env} instead."
            end
          end

          [value, resolved_env]
        rescue ArgumentError
          raise ArgumentError,
            "Expected #{source} #{resolved_env} to be a #{@definition.type}, " \
                              "but '#{env_vars[resolved_env]}' was provided"
        end

        # Anchor object that represents a value that is not set.
        # This is necessary because `nil` is a valid value to be set.
        UNSET = Object.new
        private_constant :UNSET
      end
    end
  end
end
