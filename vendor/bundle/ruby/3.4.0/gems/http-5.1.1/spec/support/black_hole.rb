# frozen_string_literal: true

module BlackHole
  class << self
    def method_missing(*)
      self
    end

    def respond_to_missing?(*)
      true
    end
  end
end
