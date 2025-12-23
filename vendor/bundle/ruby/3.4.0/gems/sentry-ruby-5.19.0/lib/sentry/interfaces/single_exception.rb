# frozen_string_literal: true

require "sentry/utils/exception_cause_chain"

module Sentry
  class SingleExceptionInterface < Interface
    include CustomInspection

    SKIP_INSPECTION_ATTRIBUTES = [:@stacktrace]
    PROBLEMATIC_LOCAL_VALUE_REPLACEMENT = "[ignored due to error]".freeze
    OMISSION_MARK = "...".freeze
    MAX_LOCAL_BYTES = 1024

    attr_reader :type, :module, :thread_id, :stacktrace, :mechanism
    attr_accessor :value

    def initialize(exception:, mechanism:, stacktrace: nil)
      @type = exception.class.to_s
      exception_message =
        if exception.respond_to?(:detailed_message)
          exception.detailed_message(highlight: false)
        else
          exception.message || ""
        end
      exception_message = exception_message.inspect unless exception_message.is_a?(String)

      @value = Utils::EncodingHelper.encode_to_utf_8(exception_message.byteslice(0..Event::MAX_MESSAGE_SIZE_IN_BYTES))

      @module = exception.class.to_s.split('::')[0...-1].join('::')
      @thread_id = Thread.current.object_id
      @stacktrace = stacktrace
      @mechanism = mechanism
    end

    def to_hash
      data = super
      data[:stacktrace] = data[:stacktrace].to_hash if data[:stacktrace]
      data[:mechanism] = data[:mechanism].to_hash
      data
    end

    # patch this method if you want to change an exception's stacktrace frames
    # also see `StacktraceBuilder.build`.
    def self.build_with_stacktrace(exception:, stacktrace_builder:, mechanism:)
      stacktrace = stacktrace_builder.build(backtrace: exception.backtrace)

      if locals = exception.instance_variable_get(:@sentry_locals)
        locals.each do |k, v|
          locals[k] =
            begin
              v = v.inspect unless v.is_a?(String)

              if v.length >= MAX_LOCAL_BYTES
                v = v.byteslice(0..MAX_LOCAL_BYTES - 1) + OMISSION_MARK
              end

              Utils::EncodingHelper.encode_to_utf_8(v)
            rescue StandardError
              PROBLEMATIC_LOCAL_VALUE_REPLACEMENT
            end
        end

        stacktrace.frames.last.vars = locals
      end

      new(exception: exception, stacktrace: stacktrace, mechanism: mechanism)
    end
  end
end
