# frozen_string_literal: true

module RuboCop
  # The kind of Ruby that code inspected by RuboCop is written in.
  # @api private
  class TargetRuby
    KNOWN_RUBIES = [2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5].freeze
    DEFAULT_VERSION = 2.7

    OBSOLETE_RUBIES = {
      1.9 => '0.41',
      2.0 => '0.50',
      2.1 => '0.57',
      2.2 => '0.68',
      2.3 => '0.81',
      2.4 => '1.12',
      2.5 => '1.28',
      2.6 => '1.50'
    }.freeze
    private_constant :KNOWN_RUBIES, :OBSOLETE_RUBIES

    # A place where information about a target ruby version is found.
    # @api private
    class Source
      attr_reader :version, :name

      def initialize(config)
        @config = config
        @version = find_version
      end

      def to_s
        name
      end
    end

    # The target ruby version may be configured by setting the
    # `RUBOCOP_TARGET_RUBY_VERSION` environment variable.
    class RuboCopEnvVar < Source
      def name
        '`RUBOCOP_TARGET_RUBY_VERSION` environment variable'
      end

      private

      def find_version
        ENV.fetch('RUBOCOP_TARGET_RUBY_VERSION', nil)&.to_f
      end
    end

    # The target ruby version may be configured in RuboCop's config.
    # @api private
    class RuboCopConfig < Source
      def name
        "`TargetRubyVersion` parameter (in #{@config.smart_loaded_path})"
      end

      private

      def find_version
        @config.for_all_cops['TargetRubyVersion']&.to_f
      end
    end

    # The target ruby version may be found in a .gemspec file.
    # @api private
    class GemspecFile < Source
      extend NodePattern::Macros

      # @!method required_ruby_version(node)
      def_node_search :required_ruby_version, <<~PATTERN
        (send _ :required_ruby_version= $_)
      PATTERN

      # @!method gem_requirement_versions(node)
      def_node_matcher :gem_requirement_versions, <<~PATTERN
        (send (const(const _ :Gem):Requirement) :new
          {$str+ | (send $str :freeze)+ | (array $str+) | (array (send $str :freeze)+)}
        )
      PATTERN

      def name
        "`required_ruby_version` parameter (in #{gemspec_filepath})"
      end

      private

      def find_version
        file = gemspec_filepath
        return unless file && File.file?(file)

        right_hand_side = version_from_gemspec_file(file)
        return if right_hand_side.nil?

        find_minimal_known_ruby(right_hand_side)
      end

      def gemspec_filepath
        return @gemspec_filepath if defined?(@gemspec_filepath)

        @gemspec_filepath =
          @config.traverse_directories_upwards(@config.base_dir_for_path_parameters) do |dir|
            # NOTE: Can't use `dir.glob` because of JRuby 9.4.8.0 incompatibility:
            # https://github.com/jruby/jruby/issues/8358
            candidates = Pathname.glob("#{dir}/*.gemspec")
            # Bundler will use a gemspec whatever the filename is, as long as its the only one in
            # the folder.
            break candidates.first if candidates.one?
          end
      end

      def version_from_gemspec_file(file)
        processed_source = ProcessedSource.from_file(
          file, DEFAULT_VERSION, parser_engine: @config.parser_engine
        )
        return unless processed_source.valid_syntax?

        required_ruby_version(processed_source.ast).first
      end

      def version_from_right_hand_side(right_hand_side)
        gem_requirement_versions = gem_requirement_versions(right_hand_side)

        if right_hand_side.array_type? && right_hand_side.children.all?(&:str_type?)
          version_from_array(right_hand_side)
        elsif gem_requirement_versions
          gem_requirement_versions.map(&:value)
        elsif right_hand_side.str_type?
          right_hand_side.value
        end
      end

      def version_from_array(array)
        array.children.map(&:value)
      end

      def find_minimal_known_ruby(right_hand_side)
        version = version_from_right_hand_side(right_hand_side)
        return unless version

        requirement = Gem::Requirement.new(version)

        KNOWN_RUBIES.detect do |v|
          requirement.satisfied_by?(Gem::Version.new("#{v}.99"))
        end
      end
    end

    # The target ruby version may be found in a .ruby-version file.
    # @api private
    class RubyVersionFile < Source
      RUBY_VERSION_FILENAME = '.ruby-version'
      RUBY_VERSION_PATTERN = /\A(?:ruby-)?(?<version>\d+\.\d+)/.freeze

      def name
        "`#{RUBY_VERSION_FILENAME}`"
      end

      private

      def filename
        RUBY_VERSION_FILENAME
      end

      def pattern
        RUBY_VERSION_PATTERN
      end

      def find_version
        file = version_file
        return unless file && File.file?(file)

        File.read(file).match(pattern) { |md| md[:version].to_f }
      end

      def version_file
        @version_file ||= @config.find_file_upwards(filename, @config.base_dir_for_path_parameters)
      end
    end

    # The target ruby version may be found in a .tool-versions file, in a line
    # starting with `ruby`.
    # @api private
    class ToolVersionsFile < RubyVersionFile
      TOOL_VERSIONS_FILENAME = '.tool-versions'
      TOOL_VERSIONS_PATTERN = /^(?:ruby )(?<version>\d+\.\d+)/.freeze

      def name
        "`#{TOOL_VERSIONS_FILENAME}`"
      end

      private

      def filename
        TOOL_VERSIONS_FILENAME
      end

      def pattern
        TOOL_VERSIONS_PATTERN
      end
    end

    # The lock file of Bundler may identify the target ruby version.
    # @api private
    class BundlerLockFile < Source
      def name
        "`#{bundler_lock_file_path}`"
      end

      private

      def find_version
        lock_file_path = bundler_lock_file_path
        return nil unless lock_file_path

        in_ruby_section = false
        File.foreach(lock_file_path) do |line|
          # If ruby is in Gemfile.lock or gems.lock, there should be two lines
          # towards the bottom of the file that look like:
          #     RUBY VERSION
          #       ruby W.X.YpZ
          # We ultimately want to match the "ruby W.X.Y.pZ" line, but there's
          # extra logic to make sure we only start looking once we've seen the
          # "RUBY VERSION" line.
          in_ruby_section ||= line.match(/^\s*RUBY\s*VERSION\s*$/)
          next unless in_ruby_section

          # We currently only allow this feature to work with MRI ruby. If
          # jruby (or something else) is used by the project, it's lock file
          # will have a line that looks like:
          #     RUBY VERSION
          #       ruby W.X.YpZ (jruby x.x.x.x)
          # The regex won't match in this situation.
          result = line.match(/^\s*ruby\s+(\d+\.\d+)[p.\d]*\s*$/)
          return result.captures.first.to_f if result
        end
      end

      def bundler_lock_file_path
        @config.bundler_lock_file_path
      end
    end

    # If all else fails, a default version will be picked.
    # @api private
    class Default < Source
      def name
        'default'
      end

      private

      def find_version
        DEFAULT_VERSION
      end
    end

    def self.supported_versions
      KNOWN_RUBIES
    end

    SOURCES = [
      RuboCopEnvVar,
      RuboCopConfig,
      GemspecFile,
      RubyVersionFile,
      ToolVersionsFile,
      BundlerLockFile,
      Default
    ].freeze

    private_constant :SOURCES
    def initialize(config)
      @config = config
    end

    def source
      @source ||= SOURCES.each.lazy.map { |c| c.new(@config) }.detect(&:version)
    end

    def version
      source.version
    end

    def supported?
      KNOWN_RUBIES.include?(version)
    end

    def rubocop_version_with_support
      if supported?
        RuboCop::Version::STRING
      else
        OBSOLETE_RUBIES[version]
      end
    end
  end
end
