# frozen_string_literal: true

module WebMock
  class Deprecation
    class << self
      def warning(message)
        warn "WebMock deprecation warning: #{message}"
      end
    end
  end
end
