# frozen_string_literal: true

module Sentry
  class StacktraceInterface
    # @return [<Array[Frame]>]
    attr_reader :frames

    # @param frames [<Array[Frame]>]
    def initialize(frames:)
      @frames = frames
    end

    # @return [Hash]
    def to_hash
      { frames: @frames.map(&:to_hash) }
    end

    # @return [String]
    def inspect
      @frames.map(&:to_s)
    end

    private

    # Not actually an interface, but I want to use the same style
    class Frame < Interface
      attr_accessor :abs_path, :context_line, :function, :in_app, :filename,
                  :lineno, :module, :pre_context, :post_context, :vars

      def initialize(project_root, line)
        @project_root = project_root

        @abs_path = line.file
        @function = line.method if line.method
        @lineno = line.number
        @in_app = line.in_app
        @module = line.module_name if line.module_name
        @filename = compute_filename
      end

      def to_s
        "#{@filename}:#{@lineno}"
      end

      def compute_filename
        return if abs_path.nil?

        prefix =
          if under_project_root? && in_app
            @project_root
          elsif under_project_root?
            longest_load_path || @project_root
          else
            longest_load_path
          end

        prefix ? abs_path[prefix.to_s.chomp(File::SEPARATOR).length + 1..-1] : abs_path
      end

      def set_context(linecache, context_lines)
        return unless abs_path

        @pre_context, @context_line, @post_context = \
            linecache.get_file_context(abs_path, lineno, context_lines)
      end

      def to_hash(*args)
        data = super(*args)
        data.delete(:vars) unless vars && !vars.empty?
        data.delete(:pre_context) unless pre_context && !pre_context.empty?
        data.delete(:post_context) unless post_context && !post_context.empty?
        data.delete(:context_line) unless context_line && !context_line.empty?
        data
      end

      private

      def under_project_root?
        @project_root && abs_path.start_with?(@project_root)
      end

      def longest_load_path
        $LOAD_PATH.select { |path| abs_path.start_with?(path.to_s) }.max_by(&:size)
      end
    end
  end
end
