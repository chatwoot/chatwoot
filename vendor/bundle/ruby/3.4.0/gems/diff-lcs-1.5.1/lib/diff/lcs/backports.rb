# frozen_string_literal: true

unless 0.respond_to?(:positive?)
  class Fixnum # standard:disable Lint/UnifiedInteger
    def positive?
      self > 0
    end
  end
end
