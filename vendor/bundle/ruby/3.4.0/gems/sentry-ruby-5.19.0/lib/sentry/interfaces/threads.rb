# frozen_string_literal: true

module Sentry
  class ThreadsInterface
    # @param crashed [Boolean]
    # @param stacktrace [Array]
    def initialize(crashed: false, stacktrace: nil)
      @id = Thread.current.object_id
      @name = Thread.current.name
      @current = true
      @crashed = crashed
      @stacktrace = stacktrace
    end

    # @return [Hash]
    def to_hash
      {
        values: [
          {
            id: @id,
            name: @name,
            crashed: @crashed,
            current: @current,
            stacktrace: @stacktrace&.to_hash
          }
        ]
      }
    end

    # Builds the ThreadsInterface with given backtrace and stacktrace_builder.
    # Patch this method if you want to change a threads interface's stacktrace frames.
    # @see StacktraceBuilder.build
    # @param backtrace [Array]
    # @param stacktrace_builder [StacktraceBuilder]
    # @param crashed [Hash]
    # @return [ThreadsInterface]
    def self.build(backtrace:, stacktrace_builder:, **options)
      stacktrace = stacktrace_builder.build(backtrace: backtrace) if backtrace
      new(**options, stacktrace: stacktrace)
    end
  end
end
