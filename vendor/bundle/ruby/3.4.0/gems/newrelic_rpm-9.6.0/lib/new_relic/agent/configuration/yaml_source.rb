# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/configuration/dotted_hash'

module NewRelic
  module Agent
    module Configuration
      class YamlSource < DottedHash
        attr_accessor :file_path, :failures
        attr_reader :generated_for_user, :license_key

        # These are configuration options that have a value of a Hash
        # This is used in YamlSource#dot_flattened prevent flattening these values
        CONFIG_WITH_HASH_VALUE = %w[expected_messages ignore_messages]

        def initialize(path, env)
          @path = path
          config = {}
          @failures = []

          # These are needed in process_erb for populating the newrelic.yml via
          # erb binding, necessary when using the default newrelic.yml file. They
          # are defined as ivars instead of local variables to prevent
          # `assigned but unused variable` warnings when running with -W
          @generated_for_user = ''
          @license_key = ''

          begin
            @file_path = validate_config_file_path(path)
            return unless @file_path

            ::NewRelic::Agent.logger.info("Reading configuration from #{path} (#{Dir.pwd})")
            raw_file = File.read(@file_path)
            erb_file = process_erb(raw_file)
            config = process_yaml(erb_file, env, config, @file_path)
          rescue ScriptError, StandardError => e
            log_failure("Failed to read or parse configuration file at #{path}", e)
          end

          substitute_transaction_threshold(config)
          booleanify_values(config, 'agent_enabled', 'enabled')
          apply_aliases(config)

          super(config, true)
        end

        def failed?
          !@failures.empty?
        end

        protected

        def validate_config_file_path(path)
          expanded_path = File.expand_path(path)

          if path.empty? || !File.exist?(expanded_path)
            warn_missing_config_file(expanded_path)
            return
          end

          expanded_path
        end

        def warn_missing_config_file(path)
          based_on = 'unknown'
          source = ::NewRelic::Agent.config.source(:config_path)
          candidate_paths = [path]

          case source
          when DefaultSource
            based_on = 'defaults'
            candidate_paths = NewRelic::Agent.config[:config_search_paths].map do |p|
              File.expand_path(p)
            end
          when EnvironmentSource
            based_on = 'environment variable'
          when ManualSource
            based_on = 'API call'
          end

          # This is not a failure, since we do support running without a
          # newrelic.yml (configured with just ENV). It is, however, uncommon,
          # so warn about it since it's very likely to be unintended.
          NewRelic::Agent.logger.warn(
            "No configuration file found. Working directory = #{Dir.pwd}",
            "Looked in these locations (based on #{based_on}): #{candidate_paths.join(', ')}"
          )
        end

        def process_erb(file)
          begin
            # Exclude lines that are commented out so failing Ruby code in an
            # ERB template commented at the YML level is fine. Leave the line,
            # though, so ERB line numbers remain correct.
            file.gsub!(/^\s*#.*$/, '#')
            ERB.new(file).result(binding)
          rescue ScriptError, StandardError => e
            log_failure('Failed ERB processing configuration file. This is typically caused by a Ruby error in <% %> templating blocks in your newrelic.yml file.', e)
            nil
          end
        end

        def process_yaml(file, env, config, path)
          if file
            confighash = if YAML.respond_to?(:unsafe_load)
              YAML.unsafe_load(file)
            else
              YAML.load(file)
            end

            unless confighash.key?(env)
              log_failure("Config file at #{path} doesn't include a '#{env}' section!")
            end

            config = confighash[env] || {}
          end

          config
        end

        def substitute_transaction_threshold(config)
          if config['transaction_tracer'] &&
              config['transaction_tracer']['transaction_threshold'].to_s =~ /apdex_f/i
            # when value is "apdex_f" remove the config and defer to default
            config['transaction_tracer'].delete('transaction_threshold')
          elsif /apdex_f/i.match?(config['transaction_tracer.transaction_threshold'].to_s)
            config.delete('transaction_tracer.transaction_threshold')
          end
        end

        def booleanify_values(config, *keys)
          # auto means defer to default
          keys.each do |option|
            if 'auto' == config[option]
              config.delete(option)
            elsif !config[option].nil? && !is_boolean?(config[option])
              coerced_value = config[option].to_s.match?(/yes|on|true/i)
              if !coerced_value
                log_failure("Unexpected value (#{config[option]}) for '#{option}' in #{@path}")
              end
              config[option] = coerced_value
            end
          end
        end

        def is_boolean?(value)
          !!value == value
        end

        def log_failure(*messages)
          ::NewRelic::Agent.logger.error(*messages)
          messages.each { |message| @failures << message }
        end

        def dot_flattened(nested_hash, names = [], result = {})
          nested_hash.each do |key, val|
            next if val.nil?

            if val.respond_to?(:has_key?) && !CONFIG_WITH_HASH_VALUE.include?(key)
              dot_flattened(val, names + [key], result)
            else
              result[(names + [key]).join('.')] = val
            end
          end
          result
        end

        def apply_aliases(config)
          DEFAULTS.each do |config_setting, value|
            next unless value[:aliases]

            value[:aliases].each do |config_alias|
              next unless config[config_setting].nil? && !config[config_alias.to_s].nil?

              config[config_setting] = config[config_alias.to_s]
            end
          end
        end
      end
    end
  end
end
