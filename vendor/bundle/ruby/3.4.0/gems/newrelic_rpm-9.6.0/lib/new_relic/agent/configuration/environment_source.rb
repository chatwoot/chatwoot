# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Configuration
      class EnvironmentSource < DottedHash
        SUPPORTED_PREFIXES = /^new_relic_|^newrelic_/i
        SPECIAL_CASE_KEYS = [
          'NEW_RELIC_ENV', # read by NewRelic::Control::Frameworks::Ruby
          'NEW_RELIC_LOG', # read by set_log_file
          /^NEW_RELIC_METADATA_/ # read by NewRelic::Agent::Connect::RequestBuilder
        ]

        attr_accessor :alias_map, :type_map

        def initialize
          set_log_file
          set_config_file

          @alias_map = {}
          @type_map = {}

          DEFAULTS.each do |config_setting, value|
            self.type_map[config_setting] = value[:type]
            set_aliases(config_setting, value)
          end

          set_values_from_new_relic_environment_variables
        end

        def set_aliases(config_setting, value)
          set_dotted_alias(config_setting)

          return unless value[:aliases]

          value[:aliases].each do |config_alias|
            self.alias_map[config_alias] = config_setting
          end
        end

        def set_dotted_alias(original_config_setting)
          config_setting = original_config_setting.to_s

          if config_setting.include?('.')
            config_alias = config_setting.tr('.', '_').to_sym
            self.alias_map[config_alias] = original_config_setting
          end
        end

        def set_log_file
          if ENV['NEW_RELIC_LOG']
            if ENV['NEW_RELIC_LOG'].casecmp(NewRelic::STANDARD_OUT) == 0
              self[:log_file_path] = self[:log_file_name] = NewRelic::STANDARD_OUT
            else
              self[:log_file_path] = File.dirname(ENV['NEW_RELIC_LOG'])
              self[:log_file_name] = File.basename(ENV['NEW_RELIC_LOG'])
            end
          end
        end

        def set_config_file
          self[:config_path] = ENV['NRCONFIG'] if ENV['NRCONFIG']
        end

        def set_values_from_new_relic_environment_variables
          nr_env_var_keys = collect_new_relic_environment_variable_keys

          nr_env_var_keys.each do |key|
            next if SPECIAL_CASE_KEYS.any? { |pattern| pattern === key.upcase }

            set_value_from_environment_variable(key)
          end
        end

        def set_value_from_environment_variable(key)
          config_key = convert_environment_key_to_config_key(key)
          set_key_by_type(config_key, key)
        end

        def set_key_by_type(config_key, environment_key)
          value = ENV[environment_key]
          type = self.type_map[config_key]

          if type == String
            self[config_key] = value
          elsif type == Integer
            self[config_key] = value.to_i
          elsif type == Float
            self[config_key] = value.to_f
          elsif type == Symbol
            self[config_key] = value.to_sym
          elsif type == Array
            self[config_key] = value.split(/\s*,\s*/)
          elsif type == NewRelic::Agent::Configuration::Boolean
            if /false|off|no/i.match?(value)
              self[config_key] = false
            elsif !value.nil?
              self[config_key] = true
            end
          else
            ::NewRelic::Agent.logger.info("#{environment_key} does not have a corresponding configuration setting (#{config_key} does not exist).")
            ::NewRelic::Agent.logger.info('Run `rake newrelic:config:docs` or visit https://docs.newrelic.com/docs/apm/agents/ruby-agent/configuration/ruby-agent-configuration to see a list of available configuration settings.')
            self[config_key] = value
          end
        end

        def convert_environment_key_to_config_key(key)
          stripped_key = key.gsub(SUPPORTED_PREFIXES, '').downcase.to_sym
          self.alias_map[stripped_key] || stripped_key
        end

        def collect_new_relic_environment_variable_keys
          ENV.keys.select { |key| key.match(SUPPORTED_PREFIXES) }
        end
      end
    end
  end
end
