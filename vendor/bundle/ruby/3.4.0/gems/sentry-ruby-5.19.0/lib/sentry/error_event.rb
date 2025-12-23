# frozen_string_literal: true

module Sentry
  # ErrorEvent represents error or normal message events.
  class ErrorEvent < Event
    # @return [ExceptionInterface]
    attr_reader :exception

    # @return [ThreadsInterface]
    attr_reader :threads

    # @return [Hash]
    def to_hash
      data = super
      data[:threads] = threads.to_hash if threads
      data[:exception] = exception.to_hash if exception
      data
    end

    # @!visibility private
    def add_threads_interface(backtrace: nil, **options)
      @threads = ThreadsInterface.build(
        backtrace: backtrace,
        stacktrace_builder: @stacktrace_builder,
        **options
      )
    end

    # @!visibility private
    def add_exception_interface(exception, mechanism:)
      if exception.respond_to?(:sentry_context)
        @extra.merge!(exception.sentry_context)
      end

      @exception = Sentry::ExceptionInterface.build(exception: exception, stacktrace_builder: @stacktrace_builder, mechanism: mechanism)
    end
  end
end
