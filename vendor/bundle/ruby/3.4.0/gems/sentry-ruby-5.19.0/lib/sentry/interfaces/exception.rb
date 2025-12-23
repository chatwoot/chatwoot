# frozen_string_literal: true

require "set"

module Sentry
  class ExceptionInterface < Interface
    # @return [<Array[SingleExceptionInterface]>]
    attr_reader :values

    # @param exceptions [Array<SingleExceptionInterface>]
    def initialize(exceptions:)
      @values = exceptions
    end

    # @return [Hash]
    def to_hash
      data = super
      data[:values] = data[:values].map(&:to_hash) if data[:values]
      data
    end

    # Builds ExceptionInterface with given exception and stacktrace_builder.
    # @param exception [Exception]
    # @param stacktrace_builder [StacktraceBuilder]
    # @see SingleExceptionInterface#build_with_stacktrace
    # @see SingleExceptionInterface#initialize
    # @param mechanism [Mechanism]
    # @return [ExceptionInterface]
    def self.build(exception:, stacktrace_builder:, mechanism:)
      exceptions = Sentry::Utils::ExceptionCauseChain.exception_to_array(exception).reverse
      processed_backtrace_ids = Set.new

      exceptions = exceptions.map do |e|
        if e.backtrace && !processed_backtrace_ids.include?(e.backtrace.object_id)
          processed_backtrace_ids << e.backtrace.object_id
          SingleExceptionInterface.build_with_stacktrace(exception: e, stacktrace_builder: stacktrace_builder, mechanism: mechanism)
        else
          SingleExceptionInterface.new(exception: exception, mechanism: mechanism)
        end
      end

      new(exceptions: exceptions)
    end
  end
end
