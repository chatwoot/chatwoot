# frozen_string_literal: true

module RuboCop
  # This class finds target files to inspect by scanning the directory tree and picking ruby files.
  # @api private
  class TargetFinder
    HIDDEN_PATH_SUBSTRING = "#{File::SEPARATOR}."

    def initialize(config_store, options = {})
      @config_store = config_store
      @options = options
    end

    # Generate a list of target files by expanding globbing patterns (if any). If args is empty,
    # recursively find all Ruby source files under the current directory
    # @return [Array] array of file paths
    def find(args, mode)
      return target_files_in_dir if args.empty?

      files = []

      args.uniq.each do |arg|
        files += if File.directory?(arg)
                   target_files_in_dir(arg.chomp(File::SEPARATOR))
                 else
                   process_explicit_path(arg, mode)
                 end
      end

      files.map { |f| File.expand_path(f) }.uniq
    end

    # Finds all Ruby source files under the current or other supplied directory. A Ruby source file
    # is defined as a file with the `.rb` extension or a file with no extension that has a ruby
    # shebang line as its first line.
    # It is possible to specify includes and excludes using the config file, so you can include
    # other Ruby files like Rakefiles and gemspecs.
    # @param base_dir Root directory under which to search for
    #   ruby source files
    # @return [Array] Array of filenames
    def target_files_in_dir(base_dir = Dir.pwd)
      # Support Windows: Backslashes from command-line -> forward slashes
      base_dir = base_dir.gsub(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
      all_files = find_files(base_dir, File::FNM_DOTMATCH)
      # use file.include? for performance optimization
      hidden_files = all_files.select { |file| file.include?(HIDDEN_PATH_SUBSTRING) }.sort
      base_dir_config = @config_store.for(base_dir)

      target_files = if base_dir.include?(HIDDEN_PATH_SUBSTRING)
                       all_files.select { |file| ruby_file?(file) }
                     else
                       all_files.select { |file| to_inspect?(file, hidden_files, base_dir_config) }
                     end

      target_files.sort_by!(&order)
    end

    # Search for files recursively starting at the given base directory using the given flags that
    # determine how the match is made. Excluded files will be removed later by the caller, but as an
    # optimization find_files removes the top level directories that are excluded in configuration
    # in the normal way (dir/**/*).
    def find_files(base_dir, flags)
      # get all wanted directories first to improve speed of finding all files
      exclude_pattern = combined_exclude_glob_patterns(base_dir)
      dir_flags = flags | File::FNM_PATHNAME | File::FNM_EXTGLOB
      patterns = wanted_dir_patterns(base_dir, exclude_pattern, dir_flags)
      patterns.map! { |dir| File.join(dir, '*') }
      # We need this special case to avoid creating the pattern
      # /**/* which searches the entire file system.
      patterns = [File.join(base_dir, '**/*')] if patterns.empty?

      Dir.glob(patterns, flags).select { |path| FileTest.file?(path) }
    end

    private

    def to_inspect?(file, hidden_files, base_dir_config)
      return false if base_dir_config.file_to_exclude?(file)
      return true if !hidden_files.bsearch do |hidden_file|
        file <=> hidden_file
      end && ruby_file?(file)

      base_dir_config.file_to_include?(file)
    end

    def wanted_dir_patterns(base_dir, exclude_pattern, flags)
      # Escape glob characters in base_dir to avoid unwanted behavior.
      base_dir = base_dir.gsub(/[\\\{\}\[\]\*\?]/) do |reserved_glob_character|
        "\\#{reserved_glob_character}"
      end

      dirs = Dir.glob(File.join(base_dir, '*/'), flags)
                .reject do |dir|
                  next true if dir.end_with?('/./', '/../')
                  next true if File.fnmatch?(exclude_pattern, dir, flags)

                  symlink_excluded_or_infinite_loop?(base_dir, dir, exclude_pattern, flags)
                end
      dirs.flat_map { |dir| wanted_dir_patterns(dir, exclude_pattern, flags) }.unshift(base_dir)
    end

    def symlink_excluded_or_infinite_loop?(base_dir, current_dir, exclude_pattern, flags)
      dir_realpath = File.realpath(current_dir)
      File.symlink?(current_dir.chomp('/')) && (
        File.fnmatch?(exclude_pattern, "#{dir_realpath}/", flags) ||
        File.realpath(base_dir).start_with?(dir_realpath)
      )
    end

    def combined_exclude_glob_patterns(base_dir)
      exclude = @config_store.for(base_dir).for_all_cops['Exclude'] || []
      patterns = exclude.select { |pattern| pattern.is_a?(String) && pattern.end_with?('/**/*') }
                        .map { |pattern| pattern.sub("#{base_dir}/", '') }
      "#{base_dir}/{#{patterns.join(',')}}"
    end

    def ruby_filenames
      @ruby_filenames ||= begin
        file_patterns = all_cops_include.reject { |pattern| pattern.start_with?('**/*.') }
        file_patterns.map { |pattern| pattern.sub('**/', '') }
      end
    end

    def all_cops_include
      @all_cops_include ||= @config_store.for_pwd.for_all_cops['Include'].map(&:to_s)
    end

    def process_explicit_path(path, mode)
      files = path.include?('*') ? Dir[path] : [path]

      if mode == :only_recognized_file_types || force_exclusion?
        files.select! { |file| included_file?(file) }
      end
      files.reject! { |file| FileTest.directory?(file) }

      force_exclusion? ? without_excluded(files) : files
    end

    def without_excluded(files)
      files.reject do |file|
        # When --ignore-parent-exclusion is given, we must look at the configuration associated with
        # the file, but in the default case when --ignore-parent-exclusion is not given, can safely
        # look only at the configuration for the current directory, since it's only the Exclude
        # parameters we're going to check.
        config = @config_store.for(ignore_parent_exclusion? ? file : '.')
        config.file_to_exclude?(file)
      end
    end

    def included_file?(file)
      ruby_file?(file) || configured_include?(file)
    end

    def ruby_file?(file)
      stdin? || ruby_extension?(file) || ruby_filename?(file) || ruby_executable?(file)
    end

    def stdin?
      @options.key?(:stdin)
    end

    def ruby_extension?(file)
      ruby_extensions.include?(File.extname(file))
    end

    def ruby_extensions
      @ruby_extensions ||= begin
        ext_patterns = all_cops_include.select { |pattern| pattern.start_with?('**/*.') }
        ext_patterns.map { |pattern| pattern.sub('**/*', '') }
      end
    end

    def ruby_filename?(file)
      ruby_filenames.include?(File.basename(file))
    end

    def configured_include?(file)
      @config_store.for_pwd.file_to_include?(file)
    end

    def ruby_executable?(file)
      return false if !File.extname(file).empty? || !File.exist?(file) || File.empty?(file)

      first_line = File.open(file, &:readline)
      /#!.*(#{ruby_interpreters(file).join('|')})/.match?(first_line)
    rescue EOFError, ArgumentError => e
      warn("Unprocessable file #{file}: #{e.class}, #{e.message}") if debug?

      false
    end

    def ruby_interpreters(file)
      @config_store.for(file).for_all_cops['RubyInterpreters']
    end

    def order
      if fail_fast?
        # Most recently modified file first.
        ->(path) { -Integer(File.mtime(path)) }
      else
        :itself
      end
    end

    def force_exclusion?
      @options[:force_exclusion]
    end

    def ignore_parent_exclusion?
      @options[:ignore_parent_exclusion]
    end

    def debug?
      @options[:debug]
    end

    def fail_fast?
      @options[:fail_fast]
    end
  end
end
