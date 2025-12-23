# frozen_string_literal: true

module WebMock
  class AssertionFailure
    @error_class = RuntimeError
    class << self
      attr_accessor :error_class
      def failure(message)
        raise @error_class.new(message)
      end
    end
  end
end
