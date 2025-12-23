# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Gapic
  ##
  # Config is a simple DSL for creating Configuration classes.
  #
  # @example
  #   require "gapic/config"
  #
  #   class SampleConfig
  #     extend Gapic::Config
  #
  #     config_attr :name,   nil,         String, nil
  #     config_attr :active, true,        true, false
  #     config_attr :count,  nil,         Numeric, nil
  #     config_attr :env,    :production, String, Symbol
  #
  #     def initialize parent_config = nil
  #       @parent_config = parent_config unless parent_config.nil?
  #       yield self if block_given?
  #     end
  #   end
  #
  #   config = SampleConfig.new
  #
  #   config.name             #=> nil
  #   config.name = "thor"    #=> "thor"
  #   config.name             #=> "thor"
  #   config.name = :thor     # ArgumentError
  #
  module Config
    ##
    # Add configuration attribute methods to the configuratin class.
    #
    # @param [String, Symbol] name The name of the option
    # @param [Object, nil] default Initial value (nil is allowed)
    # @param [Array] valid_values A list of valid types
    #
    def config_attr name, default, *valid_values, &validator
      name = String(name).to_sym
      name_setter = "#{name}=".to_sym
      raise NameError, "invalid config name #{name}" if name !~ /^[a-zA-Z]\w*$/ || name == :parent_config
      raise NameError, "method #{name} already exists" if method_defined? name
      raise NameError, "method #{name_setter} already exists" if method_defined? name_setter

      raise ArgumentError, "validation must be provided" if validator.nil? && valid_values.empty?
      validator ||= ->(value) { valid_values.any? { |v| v === value } }

      name_ivar = "@#{name}".to_sym

      create_getter name_ivar, name, default
      create_setter name_ivar, name_setter, default, validator
    end

    private

    def create_getter name_ivar, name, default
      define_method name do
        return instance_variable_get name_ivar if instance_variable_defined? name_ivar

        if instance_variable_defined? :@parent_config
          parent = instance_variable_get :@parent_config
          return parent.__send__ name if parent.respond_to? name
        end

        default
      end
    end

    def create_setter name_ivar, name_setter, default, validator
      define_method name_setter do |new_value|
        valid_value = validator.call new_value
        if new_value.nil?
          # Always allow nil when a default value is present
          valid_value ||= !default.nil?
          valid_value ||= begin
            # Allow nil if parent config has the getter method.
            parent = instance_variable_get :@parent_config if instance_variable_defined? :@parent_config
            parent&.respond_to? name_setter
          end
        end
        raise ArgumentError unless valid_value

        if new_value.nil?
          remove_instance_variable name_ivar if instance_variable_defined? name_ivar
        else
          instance_variable_set name_ivar, new_value
        end
      end
    end
  end
end
