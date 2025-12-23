# frozen_string_literal: true

require_relative 'option_definition'

module Datadog
  module Core
    module Configuration
      # Behavior for a configuration object that has options
      # @public_api
      module Options
        def self.included(base)
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        # Class behavior for a configuration object with options
        # @public_api
        module ClassMethods
          def options
            # Allows for class inheritance of option definitions
            @options ||= (superclass <= Options) ? superclass.options.dup : {}
          end

          protected

          def option(name, meta = {}, &block)
            settings_name = defined?(@settings_name) && @settings_name
            option_name = settings_name ? "#{settings_name}.#{name}" : name
            builder = OptionDefinition::Builder.new(option_name, meta, &block)
            options[name] = builder.to_definition.tap do
              # Resolve and define helper functions
              helpers = default_helpers(name)
              # Prevent unnecessary creation of an identical copy of helpers if there's nothing to merge
              helpers = helpers.merge(builder.helpers) unless builder.helpers.empty?
              define_helpers(helpers)
            end
          end

          private

          def default_helpers(name)
            option_name = name.to_sym

            {
              option_name.to_sym => proc do
                get_option(option_name)
              end,
              :"#{option_name}=" => proc do |value|
                set_option(option_name, value)
              end
            }
          end

          def define_helpers(helpers)
            helpers.each do |name, block|
              next unless block.is_a?(Proc)

              define_method(name, &block)
            end
          end
        end

        # Instance behavior for a configuration object with options
        # @public_api
        module InstanceMethods
          def options
            @options ||= {}
          end

          def set_option(name, value, precedence: Configuration::Option::Precedence::PROGRAMMATIC)
            resolve_option(name).set(value, precedence: precedence, resolved_env: resolved_env(name))
          end

          def unset_option(name, precedence: Configuration::Option::Precedence::PROGRAMMATIC)
            resolve_option(name).unset(precedence)
          end

          def get_option(name)
            resolve_option(name).get
          end

          def reset_option(name)
            assert_valid_option!(name)
            options[name].reset if options.key?(name)
          end

          def option_defined?(name)
            self.class.options.key?(name)
          end

          # Is this option's value the default fallback value?
          def using_default?(name)
            get_option(name) # Resolve value check if environment variable overwrote the default
            options[name].default_precedence?
          end

          def options_hash
            self.class.options.merge(options).each_with_object({}) do |(key, _), hash|
              hash[key] = get_option(key)
            end
          end

          def reset_options!
            options.each_value(&:reset)
          end

          private

          # Ensure option DSL is loaded
          def resolve_option(name)
            option = options[name]
            return option if option

            assert_valid_option!(name)
            definition = self.class.options[name]
            options[name] = definition.build(self)
          end

          def resolved_env(name)
            options[name].resolved_env if options.key?(name)
          end

          def assert_valid_option!(name)
            raise(InvalidOptionError, "#{self.class.name} doesn't define the option: #{name}") unless option_defined?(name)
          end
        end

        InvalidOptionError = Class.new(StandardError)
      end
    end
  end
end
