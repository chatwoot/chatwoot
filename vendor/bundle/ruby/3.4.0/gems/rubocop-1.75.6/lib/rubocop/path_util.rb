# frozen_string_literal: true

module RuboCop
  # Common methods and behaviors for dealing with paths.
  module PathUtil
    class << self
      attr_accessor :relative_paths_cache
    end
    self.relative_paths_cache = Hash.new { |hash, key| hash[key] = {} }

    module_function

    def relative_path(path, base_dir = Dir.pwd)
      PathUtil.relative_paths_cache[base_dir][path] ||=
        # Optimization for the common case where path begins with the base
        # dir. Just cut off the first part.
        if path.start_with?(base_dir)
          base_dir_length = base_dir.length
          result_length = path.length - base_dir_length - 1
          path[base_dir_length + 1, result_length]
        else
          path_name = Pathname.new(File.expand_path(path))
          begin
            path_name.relative_path_from(Pathname.new(base_dir)).to_s
          rescue ArgumentError
            path
          end
        end
    end

    def remote_file?(uri)
      uri.start_with?('http://', 'https://')
    end

    SMART_PATH_CACHE = {} # rubocop:disable Style/MutableConstant
    private_constant :SMART_PATH_CACHE

    def smart_path(path)
      SMART_PATH_CACHE[path] ||=
        if path.is_a?(RemoteConfig)
          path.uri.to_s
        else
          # Ideally, we calculate this relative to the project root.
          base_dir = Dir.pwd

          if path.start_with? base_dir
            relative_path(path, base_dir)
          else
            path
          end
        end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def match_path?(pattern, path)
      case pattern
      when String
        matches =
          if pattern == path
            true
          elsif glob?(pattern)
            # File name matching doesn't really work with relative patterns that start with "..". We
            # get around that problem by converting the pattern to an absolute path.
            pattern = File.expand_path(pattern) if pattern.start_with?('..')

            File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
          end

        matches || hidden_file_in_not_hidden_dir?(pattern, path)
      when Regexp
        begin
          pattern.match?(path)
        rescue ArgumentError => e
          return false if e.message.start_with?('invalid byte sequence')

          raise e
        end
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # Returns true for an absolute Unix or Windows path.
    def absolute?(path)
      %r{\A([A-Z]:)?/}i.match?(path)
    end

    # Returns true for a glob
    def glob?(path)
      path.match?(/[*{\[?]/)
    end

    def hidden_file_in_not_hidden_dir?(pattern, path)
      hidden_file?(path) &&
        File.fnmatch?(
          pattern, path,
          File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH
        ) &&
        !hidden_dir?(path)
    end

    def hidden_file?(path)
      maybe_hidden_file?(path) && File.basename(path).start_with?('.')
    end

    HIDDEN_FILE_PATTERN = "#{File::SEPARATOR}."

    # Loose check to reduce memory allocations
    def maybe_hidden_file?(path)
      return false unless path.include?(HIDDEN_FILE_PATTERN)

      separator_index = path.rindex(File::SEPARATOR)
      return false unless separator_index

      dot_index = path.index('.', separator_index + 1)
      dot_index == separator_index + 1
    end

    def hidden_dir?(path)
      File.dirname(path).split(File::SEPARATOR).any? { |dir| dir.start_with?('.') }
    end
  end
end
