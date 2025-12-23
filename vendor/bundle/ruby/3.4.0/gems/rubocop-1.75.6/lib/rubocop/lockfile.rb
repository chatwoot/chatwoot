# frozen_string_literal: true

begin
  # We might not be running with `bundle exec`, so we need to pull in Bundler ourselves,
  # in order to use `Bundler::LockfileParser`.
  require 'bundler'
rescue LoadError
  nil
end

module RuboCop
  # Encapsulation of a lockfile for use when checking for gems.
  # Does not actually resolve gems, just parses the lockfile.
  # @api private
  class Lockfile
    # @param [String, Pathname, nil] lockfile_path
    def initialize(lockfile_path = nil)
      lockfile_path ||= begin
        ::Bundler.default_lockfile if use_bundler_lock_parser?
      rescue ::Bundler::GemfileNotFound
        nil # We might not be a folder with a Gemfile, but that's okay.
      end

      @lockfile_path = lockfile_path
    end

    # Gems that the bundle directly depends on.
    # @return [Array<Bundler::Dependency>, nil]
    def dependencies
      return [] unless parser

      parser.dependencies.values
    end

    # All activated gems, including transitive dependencies.
    # @return [Array<Bundler::Dependency>, nil]
    def gems
      return [] unless parser

      # `Bundler::LockfileParser` returns `Bundler::LazySpecification` objects
      # which are not resolved, so extract the dependencies from them
      parser.dependencies.values.concat(parser.specs.flat_map(&:dependencies))
    end

    # Returns the locked versions of gems from this lockfile.
    # @param [Boolean] include_transitive_dependencies: When false, only direct dependencies
    #   are returned, i.e. those listed explicitly in the `Gemfile`.
    # @returns [Hash{String => Gem::Version}] The locked gem versions, keyed by the gems' names.
    def gem_versions(include_transitive_dependencies: true)
      return {} unless parser

      all_gem_versions = parser.specs.to_h { |spec| [spec.name, spec.version] }

      if include_transitive_dependencies
        all_gem_versions
      else
        direct_dep_names = parser.dependencies.keys
        all_gem_versions.slice(*direct_dep_names)
      end
    end

    # Whether this lockfile includes the named gem, directly or indirectly.
    # @param [String] name
    # @return [Boolean]
    def includes_gem?(name)
      gems.any? { |gem| gem.name == name }
    end

    private

    # @return [Bundler::LockfileParser, nil]
    def parser
      return @parser if defined?(@parser)

      @parser = if @lockfile_path && File.exist?(@lockfile_path) && use_bundler_lock_parser?
                  begin
                    lockfile = ::Bundler.read_file(@lockfile_path)
                    ::Bundler::LockfileParser.new(lockfile) if lockfile
                  rescue ::Bundler::BundlerError
                    nil
                  end
                end
    end

    def use_bundler_lock_parser?
      return false unless Object.const_defined?(:Bundler)

      Bundler.const_defined?(:LockfileParser) && Bundler::VERSION >= '2.0'
    end
  end
end
