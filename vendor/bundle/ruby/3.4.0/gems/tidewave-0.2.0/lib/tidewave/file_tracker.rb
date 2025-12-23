# frozen_string_literal: true

module Tidewave
  module FileTracker
    extend self

    def project_files(glob_pattern: nil, include_ignored: false)
      args = [ "ls-files", "--cached", "--others" ]
      args << "--exclude-standard" unless include_ignored
      args << glob_pattern if glob_pattern
      `git #{args.join(" ")}`.split("\n")
    end

    def read_file(path, line_offset: 0, count: nil)
      full_path = file_full_path(path)
      # Explicitly read the mtime first to avoid race conditions
      mtime = File.mtime(full_path).to_i
      content = File.read(full_path)

      if line_offset > 0 || count
        lines = content.lines
        start_idx = [ line_offset, 0 ].max
        count = (count || lines.length)
        selected_lines = lines[start_idx, count]
        content = selected_lines ? selected_lines.join : ""
      end

      [ mtime, content ]
    end

    def write_file(path, content)
      validate_ruby_syntax!(content) if ruby_file?(path)
      full_path = file_full_path(path)

      # Create the directory if it doesn't exist
      dirname = File.dirname(full_path)
      FileUtils.mkdir_p(dirname)

      # Write and return the file contents
      File.write(full_path, content)
      content
    end

    def file_full_path(path)
      File.expand_path(path, Rails.root)
    end

    def validate_path_access!(path, validate_existence: true)
      raise ArgumentError, "File path must not contain '..'" if path.include?("..")

      # Ensure the path is within the project
      full_path = file_full_path(path)

      # Verify the file is within the project directory
      unless full_path.start_with?(Rails.root.to_s + File::SEPARATOR)
        raise ArgumentError, "File path must be within the project directory"
      end

      # Verify the file exists
      if validate_existence && !File.exist?(full_path)
        raise ArgumentError, "File not found: #{path}"
      end

      true
    end

    def validate_path_is_editable!(path, atime)
      validate_path_access!(path)
      validate_path_has_been_read_since_last_write!(path, atime)

      true
    end

    def validate_path_is_writable!(path, atime)
      validate_path_access!(path, validate_existence: false)
      validate_path_has_been_read_since_last_write!(path, atime)

      true
    end

    private

    def ruby_file?(path)
      [ ".rb", ".rake", ".gemspec" ].include?(File.extname(path)) ||
        [ "Gemfile" ].include?(File.basename(path))
    end

    def validate_ruby_syntax!(content)
      RubyVM::AbstractSyntaxTree.parse(content)
    rescue SyntaxError => e
      raise "Invalid Ruby syntax: #{e.message}"
    end

    def validate_path_has_been_read_since_last_write!(path, atime)
      if atime && File.mtime(file_full_path(path)).to_i > atime
        raise ArgumentError, "File has been modified since last read, please read the file again"
      end

      true
    end
  end
end
