# frozen_string_literal: true

require 'erb'
require 'yaml'
require_relative 'config_finder'

module RuboCop
  # Raised when a RuboCop configuration file is not found.
  class ConfigNotFoundError < Error
  end

  # This class represents the configuration of the RuboCop application
  # and all its cops. A Config is associated with a YAML configuration
  # file from which it was read. Several different Configs can be used
  # during a run of the rubocop program, if files in several
  # directories are inspected.
  class ConfigLoader
    DOTFILE = ConfigFinder::DOTFILE
    RUBOCOP_HOME = File.realpath(File.join(File.dirname(__FILE__), '..', '..'))
    DEFAULT_FILE = File.join(RUBOCOP_HOME, 'config', 'default.yml')

    class << self
      include FileFinder

      PENDING_BANNER = <<~BANNER
        The following cops were added to RuboCop, but are not configured. Please set Enabled to either `true` or `false` in your `.rubocop.yml` file.

        Please also note that you can opt-in to new cops by default by adding this to your config:
          AllCops:
            NewCops: enable
      BANNER

      attr_accessor :debug, :ignore_parent_exclusion, :disable_pending_cops, :enable_pending_cops,
                    :ignore_unrecognized_cops
      attr_writer :default_configuration
      attr_reader :loaded_plugins, :loaded_features

      alias debug? debug
      alias ignore_parent_exclusion? ignore_parent_exclusion

      def clear_options
        @debug = nil
        @loaded_plugins = Set.new
        @loaded_features = Set.new
        @disable_pending_cops = nil
        @enable_pending_cops = nil
        @ignore_parent_exclusion = nil
        @ignore_unrecognized_cops = nil
        FileFinder.root_level = nil
      end

      # rubocop:disable Metrics/AbcSize
      def load_file(file, check: true)
        path = file_path(file)

        hash = load_yaml_configuration(path)

        rubocop_config = Config.create(hash, path, check: false)
        plugins = hash.delete('plugins')
        loaded_plugins = resolver.resolve_plugins(rubocop_config, plugins)
        add_loaded_plugins(loaded_plugins)

        loaded_features = resolver.resolve_requires(path, hash)
        add_loaded_features(loaded_features)

        resolver.resolve_inheritance_from_gems(hash)
        resolver.resolve_inheritance(path, hash, file, debug?)
        hash.delete('inherit_from')

        # Adding missing namespaces only after resolving requires & inheritance,
        # since both can introduce new cops that need to be considered here.
        add_missing_namespaces(path, hash)

        Config.create(hash, path, check: check)
      end
      # rubocop:enable Metrics/AbcSize

      def load_yaml_configuration(absolute_path)
        file_contents = read_file(absolute_path)
        yaml_code = Dir.chdir(File.dirname(absolute_path)) { ERB.new(file_contents).result }
        yaml_tree = check_duplication(yaml_code, absolute_path)
        hash = yaml_tree_to_hash(yaml_tree) || {}

        puts "configuration from #{absolute_path}" if debug?

        raise(TypeError, "Malformed configuration in #{absolute_path}") unless hash.is_a?(Hash)

        hash
      end

      def add_missing_namespaces(path, hash)
        # Using `hash.each_key` will cause the
        # `can't add a new key into hash during iteration` error
        obsoletion = ConfigObsoletion.new(hash)

        hash_keys = hash.keys
        hash_keys.each do |key|
          next if obsoletion.deprecated_cop_name?(key)

          q = Cop::Registry.qualified_cop_name(key, path)
          next if q == key

          hash[q] = hash.delete(key)
        end
      end

      # Return a recursive merge of two hashes. That is, a normal hash merge,
      # with the addition that any value that is a hash, and occurs in both
      # arguments, will also be merged. And so on.
      def merge(base_hash, derived_hash)
        resolver.merge(base_hash, derived_hash)
      end

      # Returns the path of .rubocop.yml searching upwards in the
      # directory structure starting at the given directory where the
      # inspected file is. If no .rubocop.yml is found there, the
      # user's home directory is checked. If there's no .rubocop.yml
      # there either, the path to the default file is returned.
      def configuration_file_for(target_dir)
        ConfigFinder.find_config_path(target_dir)
      end

      def configuration_from_file(config_file, check: true)
        return default_configuration if config_file == DEFAULT_FILE

        config = load_file(config_file, check: check)
        config.validate_after_resolution if check

        if ignore_parent_exclusion?
          print 'Ignoring AllCops/Exclude from parent folders' if debug?
        else
          add_excludes_from_files(config, config_file)
        end

        merge_with_default(config, config_file).tap do |merged_config|
          unless possible_new_cops?(merged_config)
            pending_cops = pending_cops_only_qualified(merged_config.pending_cops)
            warn_on_pending_cops(pending_cops) unless pending_cops.empty?
          end
        end
      end

      def pending_cops_only_qualified(pending_cops)
        pending_cops.select { |cop| Cop::Registry.qualified_cop?(cop.name) }
      end

      def possible_new_cops?(config)
        disable_pending_cops || enable_pending_cops ||
          config.disabled_new_cops? || config.enabled_new_cops?
      end

      def add_excludes_from_files(config, config_file)
        exclusion_file = find_last_file_upwards(DOTFILE, config_file, ConfigFinder.project_root)

        return unless exclusion_file
        return if PathUtil.relative_path(exclusion_file) == PathUtil.relative_path(config_file)

        print 'AllCops/Exclude ' if debug?
        config.add_excludes_from_higher_level(load_file(exclusion_file))
      end

      def default_configuration
        @default_configuration ||= begin
          print 'Default ' if debug?
          load_file(DEFAULT_FILE)
        end
      end

      # This API is primarily intended for testing and documenting plugins.
      # When testing a plugin using `rubocop/rspec/support`, the plugin is loaded automatically,
      # so this API is usually not needed. It is intended to be used only when implementing tests
      # that do not use `rubocop/rspec/support`.
      # rubocop:disable Metrics/MethodLength
      def inject_defaults!(config_yml_path)
        if Pathname(config_yml_path).directory?
          # TODO: Since the warning noise is expected to be high until some time after the release,
          # warnings will only be issued when `RUBYOPT=-w` is specified.
          # To proceed step by step, the next step is to remove `$VERBOSE` and always issue warning.
          # Eventually, `project_root` will no longer be accepted.
          if $VERBOSE
            warn Rainbow(<<~MESSAGE).yellow, uplevel: 1
              Use config YAML file path instead of project root directory.
              e.g., `path/to/config/default.yml`
            MESSAGE
          end
          # NOTE: For compatibility.
          project_root = config_yml_path
          path = File.join(project_root, 'config', 'default.yml')
          config = load_file(path)
        else
          hash = ConfigLoader.load_yaml_configuration(config_yml_path.to_s)
          config = Config.new(hash, config_yml_path).tap(&:make_excludes_absolute)
        end

        @default_configuration = ConfigLoader.merge_with_default(config, path)
      end
      # rubocop:enable Metrics/MethodLength

      # Returns the path RuboCop inferred as the root of the project. No file
      # searches will go past this directory.
      # @deprecated Use `RuboCop::ConfigFinder.project_root` instead.
      def project_root
        warn Rainbow(<<~WARNING).yellow, uplevel: 1
          `RuboCop::ConfigLoader.project_root` is deprecated and will be removed in RuboCop 2.0. \
          Use `RuboCop::ConfigFinder.project_root` instead.
        WARNING

        ConfigFinder.project_root
      end

      def warn_on_pending_cops(pending_cops)
        warn Rainbow(PENDING_BANNER).yellow

        pending_cops.each { |cop| warn_pending_cop cop }

        warn Rainbow('For more information: https://docs.rubocop.org/rubocop/versioning.html').yellow
      end

      def warn_pending_cop(cop)
        version = cop.metadata['VersionAdded'] || 'N/A'

        warn Rainbow("#{cop.name}: # new in #{version}").yellow
        warn Rainbow('  Enabled: true').yellow
      end

      # Merges the given configuration with the default one.
      def merge_with_default(config, config_file, unset_nil: true)
        resolver.merge_with_default(config, config_file, unset_nil: unset_nil)
      end

      # @api private
      # Used to add plugins that were required inside a config or from
      # the CLI using `--plugin`.
      def add_loaded_plugins(loaded_plugins)
        @loaded_plugins.merge(Array(loaded_plugins))
      end

      # @api private
      # Used to add features that were required inside a config or from
      # the CLI using `--require`.
      def add_loaded_features(loaded_features)
        @loaded_features.merge(Array(loaded_features))
      end

      private

      def file_path(file)
        File.absolute_path(file.is_a?(RemoteConfig) ? file.file : file)
      end

      def resolver
        @resolver ||= ConfigLoaderResolver.new
      end

      def check_duplication(yaml_code, absolute_path)
        smart_path = PathUtil.smart_path(absolute_path)
        YAMLDuplicationChecker.check(yaml_code, absolute_path) do |key1, key2|
          value = key1.value
          # .start_line is only available since ruby 2.5 / psych 3.0
          message = if key1.respond_to? :start_line
                      line1 = key1.start_line + 1
                      line2 = key2.start_line + 1
                      "#{smart_path}:#{line1}: " \
                        "`#{value}` is concealed by line #{line2}"
                    else
                      "#{smart_path}: `#{value}` is concealed by duplicate"
                    end
          warn Rainbow(message).yellow
        end
      end

      # Read the specified file, or exit with a friendly, concise message on
      # stderr. Care is taken to use the standard OS exit code for a "file not
      # found" error.
      def read_file(absolute_path)
        File.read(absolute_path, encoding: Encoding::UTF_8)
      rescue Errno::ENOENT
        raise ConfigNotFoundError, "Configuration file not found: #{absolute_path}"
      end

      def yaml_tree_to_hash(yaml_tree)
        yaml_tree_to_hash!(yaml_tree)
      rescue ::StandardError
        if defined?(::SafeYAML)
          raise 'SafeYAML is unmaintained, no longer needed and should be removed'
        end

        raise
      end

      def yaml_tree_to_hash!(yaml_tree)
        return nil unless yaml_tree

        # Optimization: Because we checked for duplicate keys, we already have the
        # yaml tree and don't need to parse it again.
        # Also see https://github.com/ruby/psych/blob/v5.1.2/lib/psych.rb#L322-L336
        class_loader = YAML::ClassLoader::Restricted.new(%w[Regexp Symbol], [])
        scanner = YAML::ScalarScanner.new(class_loader)
        visitor = YAML::Visitors::ToRuby.new(scanner, class_loader)
        visitor.accept(yaml_tree)
      end
    end

    # Initializing class ivars
    clear_options
  end
end
