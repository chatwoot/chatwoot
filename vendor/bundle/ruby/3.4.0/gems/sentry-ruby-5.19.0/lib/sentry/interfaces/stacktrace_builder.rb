# frozen_string_literal: true

module Sentry
  class StacktraceBuilder
    # @return [String]
    attr_reader :project_root

    # @return [Regexp, nil]
    attr_reader :app_dirs_pattern

    # @return [LineCache]
    attr_reader :linecache

    # @return [Integer, nil]
    attr_reader :context_lines

    # @return [Proc, nil]
    attr_reader :backtrace_cleanup_callback

    # @param project_root [String]
    # @param app_dirs_pattern [Regexp, nil]
    # @param linecache [LineCache]
    # @param context_lines [Integer, nil]
    # @param backtrace_cleanup_callback [Proc, nil]
    # @see Configuration#project_root
    # @see Configuration#app_dirs_pattern
    # @see Configuration#linecache
    # @see Configuration#context_lines
    # @see Configuration#backtrace_cleanup_callback
    def initialize(project_root:, app_dirs_pattern:, linecache:, context_lines:, backtrace_cleanup_callback: nil)
      @project_root = project_root
      @app_dirs_pattern = app_dirs_pattern
      @linecache = linecache
      @context_lines = context_lines
      @backtrace_cleanup_callback = backtrace_cleanup_callback
    end

    # Generates a StacktraceInterface with the given backtrace.
    # You can pass a block to customize/exclude frames:
    #
    # @example
    #   builder.build(backtrace) do |frame|
    #     if frame.module.match?(/a_gem/)
    #       nil
    #     else
    #       frame
    #     end
    #   end
    # @param backtrace [Array<String>]
    # @param frame_callback [Proc]
    # @yieldparam frame [StacktraceInterface::Frame]
    # @return [StacktraceInterface]
    def build(backtrace:, &frame_callback)
      parsed_lines = parse_backtrace_lines(backtrace).select(&:file)

      frames = parsed_lines.reverse.map do |line|
        frame = convert_parsed_line_into_frame(line)
        frame = frame_callback.call(frame) if frame_callback
        frame
      end.compact

      StacktraceInterface.new(frames: frames)
    end

    # Get the code location hash for a single line for where metrics where added.
    # @return [Hash]
    def metrics_code_location(unparsed_line)
      parsed_line = Backtrace::Line.parse(unparsed_line)
      frame = convert_parsed_line_into_frame(parsed_line)
      frame.to_hash.reject { |k, _| %i[project_root in_app].include?(k) }
    end

    private

    def convert_parsed_line_into_frame(line)
      frame = StacktraceInterface::Frame.new(project_root, line)
      frame.set_context(linecache, context_lines) if context_lines
      frame
    end

    def parse_backtrace_lines(backtrace)
      Backtrace.parse(
        backtrace, project_root, app_dirs_pattern, &backtrace_cleanup_callback
      ).lines
    end
  end
end
