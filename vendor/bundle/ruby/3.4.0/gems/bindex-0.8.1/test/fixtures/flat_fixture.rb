module Skiptrace
  module FlatFixture
    def self.call
      raise
    rescue => exc
      exc
    end
  end
end
