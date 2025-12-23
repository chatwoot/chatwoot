# frozen_string_literal: true

# FIXME: Moving Rails department code to RuboCop Rails will remove
# the following rubocop:disable comment.
# rubocop:disable Metrics/ClassLength
module RuboCop
  # This class represents the configuration of the RuboCop application
  # and all its cops. A Config is associated with a YAML configuration
  # file from which it was read. Several different Configs can be used
  # during a run of the rubocop program, if files in several
  # directories are inspected.
  class Config
    include PathUtil
    include FileFinder
    extend SimpleForwardable

    CopConfig = Struct.new(:name, :metadata)

    EMPTY_CONFIG = {}.freeze
    DEFAULT_RAILS_VERSION = 5.0
    attr_reader :loaded_path

    def self.create(hash, path, check: true)
      config = new(hash, path)
      config.check if check

      config
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def initialize(hash = RuboCop::ConfigLoader.default_configuration, loaded_path = nil)
      @loaded_path = loaded_path
      @for_cop = Hash.new do |h, cop|
        cop_name = cop.respond_to?(:cop_name) ? cop.cop_name : cop

        if ConfigObsoletion.deprecated_cop_name?(cop)
          # Since a deprecated cop will no longer have a qualified name (as the badge is no
          # longer valid), and since we do not want to automatically enable the cop, we just
          # set the configuration to an empty hash if it is unset.
          # This is necessary to allow a renamed cop have its old configuration merged in
          # before being used (which is necessary to allow it to be disabled via config).
          cop_options = self[cop_name].dup || {}
        else
          qualified_cop_name = Cop::Registry.qualified_cop_name(cop_name, loaded_path, warn: false)
          cop_options = self[qualified_cop_name].dup || {}
          cop_options['Enabled'] = enable_cop?(qualified_cop_name, cop_options)

          # If the cop has deprecated names (ie. it has been renamed), it is possible that
          # users will still have old configuration for the cop's old name. In this case,
          # if `ConfigObsoletion` is configured to warn rather than error (and therefore
          # RuboCop runs), we want to respect the old configuration, so merge it in.
          #
          # NOTE: If there is configuration for both the cop and a deprecated names, the old
          # configuration will be merged on top of the new configuration!
          ConfigObsoletion.deprecated_names_for(cop).each do |deprecated_cop_name|
            deprecated_config = @for_cop[deprecated_cop_name]
            next if deprecated_config.empty?

            warn Rainbow(<<~WARNING).yellow
              Warning: Using `#{deprecated_cop_name}` configuration in #{loaded_path} for `#{cop}`.
            WARNING

            cop_options.merge!(@for_cop[deprecated_cop_name])
          end
        end

        h[cop] = h[cop_name] = cop_options
      end
      @hash = hash
      @validator = ConfigValidator.new(self)

      @badge_config_cache = {}.compare_by_identity
      @clusivity_config_exists_cache = {}
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def loaded_plugins
      @loaded_plugins ||= ConfigLoader.loaded_plugins
    end

    def loaded_features
      @loaded_features ||= ConfigLoader.loaded_features
    end

    def check
      deprecation_check { |deprecation_message| warn("#{loaded_path} - #{deprecation_message}") }
      @validator.validate
      make_excludes_absolute
      self
    end

    def validate_after_resolution
      @validator.validate_after_resolution
      self
    end

    def_delegators :@hash, :[], :[]=, :delete, :dig, :each, :key?, :keys, :each_key,
                   :fetch, :map, :merge, :replace, :to_h, :to_hash, :transform_values
    def_delegators :@validator, :validate, :target_ruby_version

    def to_s
      @to_s ||= @hash.to_s
    end

    def signature
      @signature ||= Digest::SHA1.hexdigest(to_s)
    end

    # True if this is a config file that is shipped with RuboCop
    def internal?
      base_config_path = File.expand_path(File.join(ConfigLoader::RUBOCOP_HOME, 'config'))
      File.expand_path(loaded_path).start_with?(base_config_path)
    end

    def make_excludes_absolute
      each_key do |key|
        dig(key, 'Exclude')&.map! do |exclude_elem|
          if exclude_elem.is_a?(String) && !absolute?(exclude_elem)
            File.expand_path(File.join(base_dir_for_path_parameters, exclude_elem))
          else
            exclude_elem
          end
        end
      end
    end

    def add_excludes_from_higher_level(highest_config)
      return unless highest_config.for_all_cops['Exclude']

      excludes = for_all_cops['Exclude'] ||= []
      highest_config.for_all_cops['Exclude'].each do |path|
        unless path.is_a?(Regexp) || absolute?(path)
          path = File.join(File.dirname(highest_config.loaded_path), path)
        end
        excludes << path unless excludes.include?(path)
      end
    end

    def deprecation_check
      %w[Exclude Include].each do |key|
        plural = "#{key}s"
        next unless for_all_cops[plural]

        for_all_cops[key] = for_all_cops[plural] # Stay backwards compatible.
        for_all_cops.delete(plural)
        yield "AllCops/#{plural} was renamed to AllCops/#{key}"
      end
    end

    # @return [Config] for the given cop / cop name.
    # Note: the 'Enabled' attribute is calculated according to the department's
    # and 'AllCops' configuration; other attributes are not inherited.
    def for_cop(cop)
      @for_cop[cop]
    end

    # @return [Config, Hash] for the given cop / cop name.
    # If the given cop is enabled, returns its configuration hash.
    # Otherwise, returns an empty hash.
    def for_enabled_cop(cop)
      cop_enabled?(cop) ? for_cop(cop) : EMPTY_CONFIG
    end

    # @return [Config] for the given cop merged with that of its department (if any)
    # Note: the 'Enabled' attribute is same as that returned by `for_cop`
    def for_badge(badge)
      @badge_config_cache[badge] ||= begin
        department_config = self[badge.department_name]
        cop_config = for_cop(badge.to_s)
        if department_config
          department_config.merge(cop_config)
        else
          cop_config
        end
      end
    end

    # @return [Boolean] whether config for this badge has 'Include' or 'Exclude' keys
    # @api private
    def clusivity_config_for_badge?(badge)
      exists = @clusivity_config_exists_cache[badge.to_s]
      return exists unless exists.nil?

      cop_config = for_badge(badge)
      @clusivity_config_exists_cache[badge.to_s] = cop_config['Include'] || cop_config['Exclude']
    end

    # @return [Config] for the given department name.
    # Note: the 'Enabled' attribute will be present only if specified
    # at the department's level
    def for_department(department_name)
      @for_department ||= Hash.new { |h, dept| h[dept] = self[dept] || {} }
      @for_department[department_name.to_s]
    end

    def for_all_cops
      @for_all_cops ||= self['AllCops'] || {}
    end

    def cop_enabled?(name)
      !!for_cop(name)['Enabled']
    end

    def disabled_new_cops?
      for_all_cops['NewCops'] == 'disable'
    end

    def enabled_new_cops?
      for_all_cops['NewCops'] == 'enable'
    end

    def active_support_extensions_enabled?
      for_all_cops['ActiveSupportExtensionsEnabled']
    end

    def string_literals_frozen_by_default?
      for_all_cops['StringLiteralsFrozenByDefault']
    end

    def file_to_include?(file)
      relative_file_path = path_relative_to_config(file)

      # Optimization to quickly decide if the given file is hidden (on the top
      # level) and cannot be matched by any pattern.
      is_hidden = relative_file_path.start_with?('.') && !relative_file_path.start_with?('..')
      return false if is_hidden && !possibly_include_hidden?

      absolute_file_path = File.expand_path(file)

      patterns_to_include.any? do |pattern|
        if block_given?
          yield pattern, relative_file_path, absolute_file_path
        else
          match_path?(pattern, relative_file_path) || match_path?(pattern, absolute_file_path)
        end
      end
    end

    def allowed_camel_case_file?(file)
      # Gemspecs are allowed to have dashes because that fits with bundler best
      # practices in the case when the gem is nested under a namespace (e.g.,
      # `bundler-console` conveys `Bundler::Console`).
      return true if File.extname(file) == '.gemspec'

      file_to_include?(file) do |pattern, relative_path, absolute_path|
        /[A-Z]/.match?(pattern.to_s) &&
          (match_path?(pattern, relative_path) || match_path?(pattern, absolute_path))
      end
    end

    # Returns true if there's a chance that an Include pattern matches hidden
    # files, false if that's definitely not possible.
    def possibly_include_hidden?
      return @possibly_include_hidden if defined?(@possibly_include_hidden)

      @possibly_include_hidden = patterns_to_include.any? do |s|
        s.is_a?(Regexp) || s.start_with?('.') || s.include?('/.')
      end
    end

    def file_to_exclude?(file)
      file = File.expand_path(file)
      patterns_to_exclude.any? { |pattern| match_path?(pattern, file) }
    end

    def patterns_to_include
      for_all_cops['Include'] || []
    end

    def patterns_to_exclude
      for_all_cops['Exclude'] || []
    end

    def path_relative_to_config(path)
      relative_path(path, base_dir_for_path_parameters)
    end

    # Paths specified in configuration files starting with .rubocop are
    # relative to the directory where that file is. Paths in other config files
    # are relative to the current directory. This is so that paths in
    # config/default.yml, for example, are not relative to RuboCop's config
    # directory since that wouldn't work.
    def base_dir_for_path_parameters
      @base_dir_for_path_parameters ||=
        if loaded_path && File.basename(loaded_path).start_with?('.rubocop') &&
           loaded_path != File.join(Dir.home, ConfigLoader::DOTFILE)
          File.expand_path(File.dirname(loaded_path))
        else
          Dir.pwd
        end
    end

    def parser_engine
      @parser_engine ||= for_all_cops.fetch('ParserEngine', :default).to_sym
    end

    def target_rails_version
      @target_rails_version ||=
        if for_all_cops['TargetRailsVersion']
          for_all_cops['TargetRailsVersion'].to_f
        elsif target_rails_version_from_bundler_lock_file
          target_rails_version_from_bundler_lock_file
        else
          DEFAULT_RAILS_VERSION
        end
    end

    def smart_loaded_path
      PathUtil.smart_path(@loaded_path)
    end

    # @return [String, nil]
    def bundler_lock_file_path
      return nil unless loaded_path

      base_path = base_dir_for_path_parameters
      ['Gemfile.lock', 'gems.locked'].each do |file_name|
        path = find_file_upwards(file_name, base_path)
        return path if path
      end
      nil
    end

    def pending_cops
      keys.each_with_object([]) do |qualified_cop_name, pending_cops|
        department = department_of(qualified_cop_name)
        next if department && department['Enabled'] == false

        cop_metadata = self[qualified_cop_name]
        next unless cop_metadata['Enabled'] == 'pending'

        pending_cops << CopConfig.new(qualified_cop_name, cop_metadata)
      end
    end

    # Returns target's locked gem versions (i.e. from Gemfile.lock or gems.locked)
    # @returns [Hash{String => Gem::Version}] The locked gem versions, keyed by the gems' names.
    def gem_versions_in_target
      @gem_versions_in_target ||= read_gem_versions_from_target_lockfile
    end

    def inspect # :nodoc:
      "#<#{self.class.name}:#{object_id} @loaded_path=#{loaded_path}>"
    end

    private

    # @return [Float, nil] The Rails version as a `major.minor` Float.
    def target_rails_version_from_bundler_lock_file
      @target_rails_version_from_bundler_lock_file ||= read_rails_version_from_bundler_lock_file
    end

    # @return [Float, nil] The Rails version as a `major.minor` Float.
    def read_rails_version_from_bundler_lock_file
      return nil unless gem_versions_in_target

      # Look for `railties` instead of `rails`, to support apps that only use a subset of `rails`
      # See https://github.com/rubocop/rubocop/pull/11289
      rails_version_in_target = gem_versions_in_target['railties']
      return nil unless rails_version_in_target

      gem_version_to_major_minor_float(rails_version_in_target)
    end

    # @param [Gem::Version] gem_version an object like `Gem::Version.new("7.1.2.3")`
    # @return [Float] The major and minor version, like `7.1`
    def gem_version_to_major_minor_float(gem_version)
      segments = gem_version.segments
      Float("#{segments[0]}.#{segments[1]}")
    end

    # @returns [Hash{String => Gem::Version}] The locked gem versions, keyed by the gems' names.
    def read_gem_versions_from_target_lockfile
      lockfile_path = bundler_lock_file_path
      return nil unless lockfile_path

      Lockfile.new(lockfile_path).gem_versions
    end

    def enable_cop?(qualified_cop_name, cop_options)
      # If the cop is explicitly enabled or `Lint/Syntax`, the other checks can be skipped.
      return true if cop_options['Enabled'] == true || qualified_cop_name == 'Lint/Syntax'

      department = department_of(qualified_cop_name)
      cop_enabled = cop_options.fetch('Enabled') { !for_all_cops['DisabledByDefault'] }
      return true if cop_enabled == 'override_department'
      return false if department && department['Enabled'] == false

      cop_enabled
    end

    def department_of(qualified_cop_name)
      *cop_department, _ = qualified_cop_name.split('/')
      return nil if cop_department.empty?

      self[cop_department.join('/')]
    end
  end
end
# rubocop:enable Metrics/ClassLength
