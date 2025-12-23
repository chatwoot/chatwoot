# frozen_string_literal: true

module WebConsole
  class ExceptionMapper
    attr_reader :exc

    def self.follow(exc)
      mappers = [new(exc)]

      while cause = (cause || exc).cause
        mappers << new(cause)
      end

      mappers
    end

    def self.find_binding(mappers, exception_object_id)
      mappers.detect do |exception_mapper|
        exception_mapper.exc.object_id == exception_object_id.to_i
      end || mappers.first
    end

    def initialize(exception)
      @backtrace = exception.backtrace
      @bindings = exception.bindings
      @exc = exception
    end

    def first
      guess_the_first_application_binding || @bindings.first
    end

    def [](index)
      guess_binding_for_index(index) || @bindings[index]
    end

    private

      def guess_binding_for_index(index)
        file, line = @backtrace[index].to_s.split(":")
        line = line.to_i

        @bindings.find do |binding|
          source_location = SourceLocation.new(binding)
          source_location.path == file && source_location.lineno == line
        end
      end

      def guess_the_first_application_binding
        @bindings.find do |binding|
          source_location = SourceLocation.new(binding)
          source_location.path.to_s.start_with?(Rails.root.to_s)
        end
      end
  end
end
