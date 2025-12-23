# frozen_string_literal: true

module RuboCop
  # Handles validation of configuration, for example cop names, parameter
  # names, and Ruby versions.
  # rubocop:disable Metrics/ClassLength
  class ConfigValidator
    extend SimpleForwardable

    # @api private
    COMMON_PARAMS = %w[Exclude Include Severity inherit_mode AutoCorrect StyleGuide Details
                       Enabled Reference References].freeze
    # @api private
    INTERNAL_PARAMS = %w[Description StyleGuide
                         VersionAdded VersionChanged VersionRemoved
                         Reference References Safe SafeAutoCorrect].freeze
    # @api private
    NEW_COPS_VALUES = %w[pending disable enable].freeze

    # @api private
    CONFIG_CHECK_KEYS = %w[Enabled Safe SafeAutoCorrect AutoCorrect References].to_set.freeze
    CONFIG_CHECK_DEPARTMENTS = %w[pending override_department].freeze
    CONFIG_CHECK_AUTOCORRECTS = %w[always contextual disabled].freeze
    private_constant :CONFIG_CHECK_KEYS, :CONFIG_CHECK_DEPARTMENTS

    def_delegators :@config, :smart_loaded_path, :for_all_cops

    def initialize(config)
      @config = config
      @config_obsoletion = ConfigObsoletion.new(config)
      @target_ruby = TargetRuby.new(config)
    end

    def validate
      check_cop_config_value(@config)
      reject_conflicting_safe_settings

      # Don't validate RuboCop's own files further. Avoids infinite recursion.
      return if @config.internal?

      valid_cop_names, invalid_cop_names = @config.keys.partition do |key|
        ConfigLoader.default_configuration.key?(key)
      end

      validate_parameter_shape(valid_cop_names)

      check_obsoletions
      alert_about_unrecognized_cops(invalid_cop_names)
      validate_new_cops_parameter
      validate_parameter_names(valid_cop_names)
      validate_enforced_styles(valid_cop_names)
      validate_syntax_cop
      reject_mutually_exclusive_defaults
    end

    # Validations that should only be run after all config resolving has
    # taken place:
    # * The target ruby version is only checked once the entire inheritance
    # chain has been loaded so that only the final value is validated, and
    # any obsolete but overridden values are ignored.
    def validate_after_resolution
      check_target_ruby
    end

    def target_ruby_version
      target_ruby.version
    end

    private

    attr_reader :target_ruby

    def check_obsoletions
      @config_obsoletion.reject_obsolete!
      return unless @config_obsoletion.warnings.any?

      warn Rainbow("Warning: #{@config_obsoletion.warnings.join("\n")}").yellow
    end

    def check_target_ruby
      return if target_ruby.supported?

      source = target_ruby.source
      last_version = target_ruby.rubocop_version_with_support

      msg = if last_version
              "RuboCop found unsupported Ruby version #{target_ruby_version} " \
                "in #{source}. #{target_ruby_version}-compatible " \
                "analysis was dropped after version #{last_version}."
            else
              'RuboCop found unknown Ruby version ' \
                "#{target_ruby_version.inspect} in #{source}."
            end

      msg += "\nSupported versions: #{TargetRuby.supported_versions.join(', ')}"

      raise ValidationError, msg
    end

    def alert_about_unrecognized_cops(invalid_cop_names)
      unknown_cops = list_unknown_cops(invalid_cop_names)

      return if unknown_cops.empty?

      if ConfigLoader.ignore_unrecognized_cops
        warn Rainbow('The following cops or departments are not ' \
                     'recognized and will be ignored:').yellow
        warn unknown_cops.join("\n")

        return
      end

      raise ValidationError, unknown_cops.join("\n")
    end

    def list_unknown_cops(invalid_cop_names)
      unknown_cops = []
      invalid_cop_names.each do |name|
        # There could be a custom cop with this name. If so, don't warn
        next if Cop::Registry.global.contains_cop_matching?([name])
        next if ConfigObsoletion.deprecated_cop_name?(name)

        # Special case for inherit_mode, which is a directive that we keep in
        # the configuration (even though it's not a cop), because it's easier
        # to do so than to pass the value around to various methods.
        next if name == 'inherit_mode'

        message = <<~MESSAGE.rstrip
          unrecognized cop or department #{name} found in #{smart_loaded_path}
          #{suggestion(name)}
        MESSAGE

        unknown_cops << message
      end

      unknown_cops
    end

    def suggestion(name)
      registry = Cop::Registry.global
      departments = registry.departments.map(&:to_s)
      suggestions = NameSimilarity.find_similar_names(name, departments + registry.map(&:cop_name))
      if suggestions.any?
        "Did you mean `#{suggestions.join('`, `')}`?"
      else
        # Department names can contain slashes, e.g. Chef/Correctness, but there's no support for
        # the concept of higher level departments in RuboCop. It's a flat structure. So if the user
        # tries to configure a "top level department", we hint that it's the bottom level
        # departments that should be configured.
        suggestions = departments.select { |department| department.start_with?("#{name}/") }
        "#{name} is not a department. Use `#{suggestions.join('`, `')}`." if suggestions.any?
      end
    end

    def validate_syntax_cop
      syntax_config = @config['Lint/Syntax']
      default_config = ConfigLoader.default_configuration['Lint/Syntax']

      return unless syntax_config && default_config.merge(syntax_config) != default_config

      raise ValidationError,
            "configuration for Lint/Syntax cop found in #{smart_loaded_path}\n" \
            'It\'s not possible to disable this cop.'
    end

    def validate_new_cops_parameter
      new_cop_parameter = @config.for_all_cops['NewCops']
      return if new_cop_parameter.nil? || NEW_COPS_VALUES.include?(new_cop_parameter)

      message = "invalid #{new_cop_parameter} for `NewCops` found in" \
                "#{smart_loaded_path}\n" \
                "Valid choices are: #{NEW_COPS_VALUES.join(', ')}"

      raise ValidationError, message
    end

    def validate_parameter_shape(valid_cop_names)
      valid_cop_names.each do |name|
        if @config[name].nil?
          raise ValidationError, "empty section #{name.inspect} found in #{smart_loaded_path}"
        elsif !@config[name].is_a?(Hash)
          raise ValidationError, <<~MESSAGE
            The configuration for #{name.inspect} in #{smart_loaded_path} is not a Hash.

            Found: #{@config[name].inspect}
          MESSAGE
        end
      end
    end

    def validate_parameter_names(valid_cop_names)
      valid_cop_names.each do |name|
        each_invalid_parameter(name) do |param, supported_params|
          warn Rainbow(<<~MESSAGE).yellow
            Warning: #{name} does not support #{param} parameter.

            Supported parameters are:

              - #{supported_params.join("\n  - ")}
          MESSAGE
        end
      end
    end

    def each_invalid_parameter(cop_name)
      default_config = ConfigLoader.default_configuration[cop_name]

      @config[cop_name].each_key do |param|
        next if COMMON_PARAMS.include?(param) || default_config.key?(param)

        supported_params = default_config.keys - INTERNAL_PARAMS

        yield param, supported_params
      end
    end

    def validate_enforced_styles(valid_cop_names) # rubocop:todo Metrics/AbcSize
      valid_cop_names.each do |name|
        styles = @config[name].select { |key, _| key.start_with?('Enforced') }

        styles.each do |style_name, style|
          supported_key = RuboCop::Cop::Util.to_supported_styles(style_name)
          valid = ConfigLoader.default_configuration[name][supported_key]

          next unless valid
          next if valid.include?(style)
          next if validate_support_and_has_list(name, style, valid)

          msg = "invalid #{style_name} '#{style}' for #{name} found in " \
                "#{smart_loaded_path}\n" \
                "Valid choices are: #{valid.join(', ')}"
          raise ValidationError, msg
        end
      end
    end

    def validate_support_and_has_list(name, formats, valid)
      ConfigLoader.default_configuration[name]['AllowMultipleStyles'] &&
        formats.is_a?(Array) &&
        formats.all? { |format| valid.include?(format) }
    end

    def reject_mutually_exclusive_defaults
      disabled_by_default = for_all_cops['DisabledByDefault']
      enabled_by_default = for_all_cops['EnabledByDefault']
      return unless disabled_by_default && enabled_by_default

      msg = 'Cops cannot be both enabled by default and disabled by default'
      raise ValidationError, msg
    end

    def reject_conflicting_safe_settings
      @config.each do |name, cop_config|
        next unless cop_config.is_a?(Hash)
        next unless cop_config['Safe'] == false && cop_config['SafeAutoCorrect'] == true

        msg = 'Unsafe cops cannot have a safe autocorrection ' \
              "(section #{name} in #{smart_loaded_path})"
        raise ValidationError, msg
      end
    end

    def check_cop_config_value(hash, parent = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      hash.each do |key, value|
        check_cop_config_value(value, key) if value.is_a?(Hash)

        next unless CONFIG_CHECK_KEYS.include?(key) && value.is_a?(String)

        if key == 'Enabled' && !CONFIG_CHECK_DEPARTMENTS.include?(value)
          supposed_values = 'a boolean'
        elsif key == 'AutoCorrect' && !CONFIG_CHECK_AUTOCORRECTS.include?(value)
          supposed_values = '`always`, `contextual`, `disabled`, or a boolean'
        elsif key == 'References'
          supposed_values = 'an array of strings'
        else
          next
        end

        raise ValidationError, param_error_message(parent, key, value, supposed_values)
      end
    end

    # FIXME: Handling colors in exception messages like this is ugly.
    def param_error_message(parent, key, value, supposed_values)
      "#{Rainbow('').reset}" \
        "Property #{Rainbow(key).yellow} of #{Rainbow(parent).yellow} cop " \
        "is supposed to be #{supposed_values} and #{Rainbow(value).yellow} is not."
    end
  end
  # rubocop:enable Metrics/ClassLength
end
