# frozen_string_literal: true

require 'digest/sha1'
require 'find'
require 'zlib'
require_relative 'cache_config'

module RuboCop
  # Provides functionality for caching RuboCop runs.
  # @api private
  class ResultCache
    NON_CHANGING = %i[color format formatters out debug fail_level
                      fix_layout autocorrect safe_autocorrect autocorrect_all
                      cache fail_fast stdin parallel].freeze

    DL_EXTENSIONS = ::RbConfig::CONFIG
                    .values_at('DLEXT', 'DLEXT2')
                    .reject { |ext| !ext || ext.empty? }
                    .map    { |ext| ".#{ext}" }
                    .freeze

    # Remove old files so that the cache doesn't grow too big. When the
    # threshold MaxFilesInCache has been exceeded, the oldest 50% of all the
    # files in the cache are removed. The reason for removing so much is that
    # cleaning should be done relatively seldom, since there is a slight risk
    # that some other RuboCop process was just about to read the file, when
    # there's parallel execution and the cache is shared.
    def self.cleanup(config_store, verbose, cache_root_override = nil)
      return if inhibit_cleanup # OPTIMIZE: For faster testing

      rubocop_cache_dir = cache_root(config_store, cache_root_override)
      return unless File.exist?(rubocop_cache_dir)

      files, dirs = Find.find(rubocop_cache_dir).partition { |path| File.file?(path) }
      return unless requires_file_removal?(files.length, config_store)

      remove_oldest_files(files, dirs, rubocop_cache_dir, verbose)
    end

    class << self
      # @api private
      attr_accessor :rubocop_required_features

      ResultCache.rubocop_required_features = []

      private

      def requires_file_removal?(file_count, config_store)
        file_count > 1 && file_count > config_store.for_pwd.for_all_cops['MaxFilesInCache']
      end

      def remove_oldest_files(files, dirs, rubocop_cache_dir, verbose)
        # Add 1 to half the number of files, so that we remove the file if
        # there's only 1 left.
        remove_count = (files.length / 2) + 1
        puts "Removing the #{remove_count} oldest files from #{rubocop_cache_dir}" if verbose
        sorted = files.sort_by { |path| File.mtime(path) }
        remove_files(sorted, dirs, remove_count)
      rescue Errno::ENOENT
        # This can happen if parallel RuboCop invocations try to remove the
        # same files. No problem.
        puts $ERROR_INFO if verbose
      end

      def remove_files(files, dirs, remove_count)
        # Batch file deletions, deleting over 130,000+ files will crash
        # File.delete.
        files[0, remove_count].each_slice(10_000).each do |files_slice|
          File.delete(*files_slice)
        end
        dirs.each { |dir| Dir.rmdir(dir) if Dir["#{dir}/*"].empty? }
      end
    end

    def self.cache_root(config_store, cache_root_override = nil)
      CacheConfig.root_dir do
        cache_root_override || config_store.for_pwd.for_all_cops['CacheRootDirectory']
      end
    end

    def self.allow_symlinks_in_cache_location?(config_store)
      config_store.for_pwd.for_all_cops['AllowSymlinksInCacheRootDirectory']
    end

    attr_reader :path

    def initialize(file, team, options, config_store, cache_root_override = nil)
      cache_root_override ||= options[:cache_root] if options[:cache_root]
      rubocop_cache_dir = ResultCache.cache_root(config_store, cache_root_override)
      @allow_symlinks_in_cache_location =
        ResultCache.allow_symlinks_in_cache_location?(config_store)
      @path = File.join(rubocop_cache_dir,
                        rubocop_checksum,
                        context_checksum(team, options),
                        file_checksum(file, config_store))
      @cached_data = CachedData.new(file)
      @debug = options[:debug]
    end

    def debug?
      @debug
    end

    def valid?
      File.exist?(@path)
    end

    def load
      puts "Loading cache from #{@path}" if debug?
      @cached_data.from_json(File.read(@path, encoding: Encoding::UTF_8))
    end

    def save(offenses)
      dir = File.dirname(@path)

      begin
        FileUtils.mkdir_p(dir)
      rescue Errno::EACCES, Errno::EROFS => e
        warn "Couldn't create cache directory. Continuing without cache.\n  #{e.message}"
        return
      end

      preliminary_path = "#{@path}_#{rand(1_000_000_000)}"
      # RuboCop must be in control of where its cached data is stored. A
      # symbolic link anywhere in the cache directory tree can be an
      # indication that a symlink attack is being waged.
      return if symlink_protection_triggered?(dir)

      File.open(preliminary_path, 'w', encoding: Encoding::UTF_8) do |f|
        f.write(@cached_data.to_json(offenses))
      end
      # The preliminary path is used so that if there are multiple RuboCop
      # processes trying to save data for the same inspected file
      # simultaneously, the only problem we run in to is a competition who gets
      # to write to the final file. The contents are the same, so no corruption
      # of data should occur.
      FileUtils.mv(preliminary_path, @path)
    end

    private

    def symlink_protection_triggered?(path)
      !@allow_symlinks_in_cache_location && any_symlink?(path)
    end

    def any_symlink?(path)
      while path != File.dirname(path)
        if File.symlink?(path)
          warn "Warning: #{path} is a symlink, which is not allowed."
          return true
        end
        path = File.dirname(path)
      end
      false
    end

    def file_checksum(file, config_store)
      digester = Digest::SHA1.new
      mode = File.stat(file).mode
      digester.update("#{file}#{mode}#{config_store.for_file(file).signature}")
      digester.file(file)
      digester.hexdigest
    rescue Errno::ENOENT
      # Spurious files that come and go should not cause a crash, at least not
      # here.
      '_'
    end

    class << self
      attr_accessor :source_checksum, :inhibit_cleanup
    end

    # The checksum of the RuboCop program running the inspection.
    def rubocop_checksum
      ResultCache.source_checksum ||=
        begin
          digest = Digest::SHA1.new
          rubocop_extra_features
            .select { |path| File.file?(path) }
            .sort!
            .each do |path|
              digest << digest(path)
            end
          digest << RuboCop::Version::STRING << RuboCop::AST::Version::STRING
          digest.hexdigest
        end
    end

    def digest(path)
      content = if path.end_with?(*DL_EXTENSIONS)
                  # Shared libraries often contain timestamps of when
                  # they were compiled and other non-stable data.
                  File.basename(path)
                else
                  File.binread(path) # mtime not reliable
                end
      Zlib.crc32(content).to_s
    end

    def rubocop_extra_features
      lib_root = File.join(File.dirname(__FILE__), '..')
      exe_root = File.join(lib_root, '..', 'exe')

      # Make sure to use an absolute path to prevent errors on Windows
      # when traversing the relative paths with symlinks.
      exe_root = File.absolute_path(exe_root)

      # These are all the files we have `require`d plus everything in the
      # exe directory. A change to any of them could affect the cop output
      # so we include them in the cache hash.
      source_files = $LOADED_FEATURES + Find.find(exe_root).to_a
      source_files -= ResultCache.rubocop_required_features # Rely on gem versions

      source_files
    end

    # Return a hash of the options given at invocation, minus the ones that have
    # no effect on which offenses and disabled line ranges are found, and thus
    # don't affect caching.
    def relevant_options_digest(options)
      options = options.reject { |key, _| NON_CHANGING.include?(key) }
      options.to_s.gsub(/[^a-z]+/i, '_')
    end

    # We combine team and options into a single "context" checksum to avoid
    # making file names that are too long for some filesystems to handle.
    # This context is for anything that's not (1) the RuboCop executable
    # checksum or (2) the inspected file checksum.
    def context_checksum(team, options)
      keys = [team.external_dependency_checksum, relevant_options_digest(options)]
      Digest::SHA1.hexdigest(keys.join)
    end
  end
end
