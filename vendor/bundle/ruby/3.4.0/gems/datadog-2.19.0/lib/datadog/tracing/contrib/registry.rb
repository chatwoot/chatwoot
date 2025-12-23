# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Registry is a collection of tracing integrations.
      # @public_api
      class Registry
        include Enumerable

        Entry = Struct.new(:name, :klass, :auto_patch)

        # @!visibility private
        def initialize
          @data = {}
          @mutex = Mutex.new
        end

        # @param name [Symbol] instrumentation name, to be used when activating this integration
        # @param klass [Object] instrumentation implementation
        # @param auto_patch [Boolean] is the tracer allowed to automatically patch
        #   the host application with this instrumentation?
        def add(name, klass, auto_patch = false)
          @mutex.synchronize do
            @data[name] = Entry.new(name, klass, auto_patch).freeze
          end
        end

        def each(&block)
          @mutex.synchronize do
            @data.each_value(&block)
          end
        end

        def [](name)
          @mutex.synchronize do
            entry = @data[name]
            entry.klass if entry
          end
        end

        def to_h
          @mutex.synchronize do
            @data.each_with_object({}) do |(_, entry), hash|
              hash[entry.name] = entry.auto_patch
            end
          end
        end
      end
    end
  end
end
