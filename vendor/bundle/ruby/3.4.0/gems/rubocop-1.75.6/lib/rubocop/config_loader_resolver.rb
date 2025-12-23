# frozen_string_literal: true

require 'pathname'
require 'yaml'
require_relative 'plugin'

module RuboCop
  # A help class for ConfigLoader that handles configuration resolution.
  # @api private
  class ConfigLoaderResolver # rubocop:disable Metrics/ClassLength
    def resolve_plugins(rubocop_config, plugins)
      plugins = Array(plugins) - ConfigLoader.loaded_plugins.map { |plugin| plugin.about.name }
      return if plugins.empty?

      Plugin.integrate_plugins(rubocop_config, plugins)
    end

    def resolve_requires(path, hash)
      config_dir = File.dirname(path)
      hash.delete('require').tap do |loaded_features|
        Array(loaded_features).each do |feature|
          if Plugin.plugin_capable?(feature)
            # NOTE: Compatibility for before plugins style.
            warn Rainbow(<<~MESSAGE).yellow
              #{feature} extension supports plugin, specify `plugins: #{feature}` instead of `require: #{feature}` in #{path}.
              For more information, see https://docs.rubocop.org/rubocop/plugin_migration_guide.html.
            MESSAGE
            rubocop_config = Config.create(hash, path, check: false)

            resolve_plugins(rubocop_config, feature)
          else
            FeatureLoader.load(config_directory_path: config_dir, feature: feature)
          end
        end
      end
    end

    def resolve_inheritance(path, hash, file, debug) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      inherited_files = Array(hash['inherit_from'])
      base_configs(path, inherited_files, file)
        .each_with_index.reverse_each do |base_config, index|
        override_department_setting_for_cops(base_config, hash)
        override_enabled_for_disabled_departments(base_config, hash)

        base_config.each do |k, v|
          next unless v.is_a?(Hash)

          if hash.key?(k)
            v = merge(v, hash[k],
                      cop_name: k, file: file, debug: debug,
                      inherited_file: inherited_files[index],
                      inherit_mode: determine_inherit_mode(hash, k))
          end
          hash[k] = v
          fix_include_paths(base_config.loaded_path, hash, path, k, v) if v.key?('Include')
        end
      end
    end

    # When one .rubocop.yml file inherits from another .rubocop.yml file, the Include paths in the
    # base configuration are relative to the directory where the base configuration file is. For the
    # derived configuration, we need to make those paths relative to where the derived configuration
    # file is.
    def fix_include_paths(base_config_path, hash, path, key, value)
      return unless File.basename(base_config_path).start_with?('.rubocop')

      base_dir = File.dirname(base_config_path)
      derived_dir = File.dirname(path)
      hash[key]['Include'] = value['Include'].map do |include_path|
        PathUtil.relative_path(File.join(base_dir, include_path), derived_dir)
      end
    end

    def resolve_inheritance_from_gems(hash)
      gems = hash.delete('inherit_gem')
      (gems || {}).each_pair do |gem_name, config_path|
        if gem_name == 'rubocop'
          raise ArgumentError, "can't inherit configuration from the rubocop gem"
        end

        hash['inherit_from'] = Array(hash['inherit_from'])
        Array(config_path).reverse_each do |path|
          # Put gem configuration first so local configuration overrides it.
          hash['inherit_from'].unshift gem_config_path(gem_name, path)
        end
      end
    end

    # Merges the given configuration with the default one. If
    # AllCops:DisabledByDefault is true, it changes the Enabled params so that
    # only cops from user configuration are enabled. If
    # AllCops:EnabledByDefault is true, it changes the Enabled params so that
    # only cops explicitly disabled in user configuration are disabled.
    def merge_with_default(config, config_file, unset_nil:)
      default_configuration = ConfigLoader.default_configuration

      disabled_by_default = config.for_all_cops['DisabledByDefault']
      enabled_by_default = config.for_all_cops['EnabledByDefault']

      if disabled_by_default || enabled_by_default
        default_configuration = transform(default_configuration) do |params|
          params.merge('Enabled' => !disabled_by_default)
        end
      end

      config = handle_disabled_by_default(config, default_configuration) if disabled_by_default
      override_enabled_for_disabled_departments(default_configuration, config)

      opts = { inherit_mode: config['inherit_mode'] || {}, unset_nil: unset_nil }
      Config.new(merge(default_configuration, config, **opts), config_file)
    end

    # Return a recursive merge of two hashes. That is, a normal hash merge,
    # with the addition that any value that is a hash, and occurs in both
    # arguments, will also be merged. And so on.
    #
    # rubocop:disable Metrics/AbcSize
    def merge(base_hash, derived_hash, **opts)
      result = base_hash.merge(derived_hash)
      keys_appearing_in_both = base_hash.keys & derived_hash.keys
      keys_appearing_in_both.each do |key|
        if opts[:unset_nil] && derived_hash[key].nil?
          result.delete(key)
        elsif merge_hashes?(base_hash, derived_hash, key)
          result[key] = merge(base_hash[key], derived_hash[key], **opts)
        elsif should_union?(derived_hash, base_hash, opts[:inherit_mode], key)
          result[key] = Array(base_hash[key]) | Array(derived_hash[key])
        elsif opts[:debug]
          warn_on_duplicate_setting(base_hash, derived_hash, key, **opts)
        end
      end
      result
    end
    # rubocop:enable Metrics/AbcSize

    # An `Enabled: true` setting in user configuration for a cop overrides an
    # `Enabled: false` setting for its department.
    def override_department_setting_for_cops(base_hash, derived_hash)
      derived_hash.each_key do |key|
        next unless key =~ %r{(.*)/.*}

        department = Regexp.last_match(1)
        next unless disabled?(derived_hash, department) || disabled?(base_hash, department)

        # The `override_department` setting for the `Enabled` parameter is an
        # internal setting that's not documented in the manual. It will cause a
        # cop to be enabled later, when logic surrounding enabled/disabled it
        # run, even though its department is disabled.
        derived_hash[key]['Enabled'] = 'override_department' if derived_hash[key]['Enabled']
      end
    end

    # If a cop was previously explicitly enabled, but then superseded by the
    # department being disabled, disable it.
    def override_enabled_for_disabled_departments(base_hash, derived_hash)
      cops_to_disable = derived_hash.each_key.with_object([]) do |key, cops|
        next unless disabled?(derived_hash, key)

        cops.concat(base_hash.keys.grep(Regexp.new("^#{key}/")))
      end

      cops_to_disable.each do |cop_name|
        next unless base_hash.dig(cop_name, 'Enabled') == true

        derived_hash.replace(merge({ cop_name => { 'Enabled' => false } }, derived_hash))
      end
    end

    private

    def disabled?(hash, department)
      hash[department].is_a?(Hash) && hash[department]['Enabled'] == false
    end

    def duplicate_setting?(base_hash, derived_hash, key, inherited_file)
      return false if inherited_file.nil? # Not inheritance resolving merge
      return false if inherited_file.start_with?('..') # Legitimate override
      return false if base_hash[key] == derived_hash[key] # Same value
      return false if PathUtil.remote_file?(inherited_file) # Can't change

      Gem.path.none? { |dir| inherited_file.start_with?(dir) } # Can change?
    end

    def warn_on_duplicate_setting(base_hash, derived_hash, key, **opts)
      # If the file being considered is remote, don't bother checking for duplicates
      return if remote_config?(opts[:file])

      return unless duplicate_setting?(base_hash, derived_hash, key, opts[:inherited_file])

      inherit_mode = opts[:inherit_mode]['merge'] || opts[:inherit_mode]['override']
      return if base_hash[key].is_a?(Array) && inherit_mode&.include?(key)

      puts duplicate_setting_warning(opts, key)
    end

    def duplicate_setting_warning(opts, key)
      "#{PathUtil.smart_path(opts[:file])}: " \
        "#{opts[:cop_name]}:#{key} overrides " \
        "the same parameter in #{opts[:inherited_file]}"
    end

    def determine_inherit_mode(hash, key)
      cop_cfg = hash[key]
      local_inherit = cop_cfg['inherit_mode'] if cop_cfg.is_a?(Hash)
      local_inherit || hash['inherit_mode'] || {}
    end

    def should_union?(derived_hash, base_hash, root_mode, key)
      return false unless base_hash[key].is_a?(Array) || derived_hash[key].is_a?(Array)

      derived_mode = derived_hash['inherit_mode']
      return false if should_override?(derived_mode, key)
      return true if should_merge?(derived_mode, key)

      base_mode = base_hash['inherit_mode']
      return false if should_override?(base_mode, key)
      return true if should_merge?(base_mode, key)

      should_merge?(root_mode, key)
    end

    def should_merge?(mode, key)
      mode && mode['merge']&.include?(key)
    end

    def should_override?(mode, key)
      mode && mode['override']&.include?(key)
    end

    def merge_hashes?(base_hash, derived_hash, key)
      base_hash[key].is_a?(Hash) && derived_hash[key].is_a?(Hash)
    end

    def base_configs(path, inherit_from, file)
      inherit_froms = Array(inherit_from).compact.flat_map do |f|
        PathUtil.glob?(f) ? Dir.glob(f) : f
      end

      configs = inherit_froms.map do |f|
        ConfigLoader.load_file(inherited_file(path, f, file))
      end

      configs.compact
    end

    def inherited_file(path, inherit_from, file)
      if PathUtil.remote_file?(inherit_from)
        # A remote configuration, e.g. `inherit_from: http://example.com/rubocop.yml`.
        RemoteConfig.new(inherit_from, File.dirname(path))
      elsif Pathname.new(inherit_from).absolute?
        # An absolute path to a config, e.g. `inherit_from: /Users/me/rubocop.yml`.
        # The path may come from `inherit_gem` option, where a gem name is expanded
        # to an absolute path to that gem.
        print 'Inheriting ' if ConfigLoader.debug?
        inherit_from
      elsif file.is_a?(RemoteConfig)
        # A path relative to a URL, e.g. `inherit_from: configs/default.yml`
        # in a config included with `inherit_from: http://example.com/rubocop.yml`
        file.inherit_from_remote(inherit_from, path)
      else
        # A local relative path, e.g. `inherit_from: default.yml`
        print 'Inheriting ' if ConfigLoader.debug?
        File.expand_path(inherit_from, File.dirname(path))
      end
    end

    def remote_config?(file)
      file.is_a?(RemoteConfig)
    end

    def handle_disabled_by_default(config, new_default_configuration)
      department_config = config.to_hash.reject { |cop| cop.include?('/') }
      department_config.each do |dept, dept_params|
        next unless dept_params['Enabled']

        new_default_configuration.each do |cop, params|
          next unless cop.start_with?("#{dept}/")

          # Retain original default configuration for cops in the department.
          params['Enabled'] = ConfigLoader.default_configuration[cop]['Enabled']
        end
      end

      transform(config) do |params|
        { 'Enabled' => true }.merge(params) # Set true if not set.
      end
    end

    def transform(config, &block)
      config.transform_values(&block)
    end

    def gem_config_path(gem_name, relative_config_path)
      if defined?(Bundler)
        begin
          gem = Bundler.load.specs[gem_name].first
          gem_path = gem.full_gem_path if gem
        rescue Bundler::GemfileNotFound
          # No Gemfile found. Bundler may be loaded manually
        rescue Bundler::GitError
          # The Gemfile exists but contains an uninstalled git source
        end
      end

      gem_path ||= Gem::Specification.find_by_name(gem_name).gem_dir

      File.join(gem_path, relative_config_path)
    rescue Gem::LoadError => e
      raise Gem::LoadError, "Unable to find gem #{gem_name}; is the gem installed? #{e}"
    end
  end
end
