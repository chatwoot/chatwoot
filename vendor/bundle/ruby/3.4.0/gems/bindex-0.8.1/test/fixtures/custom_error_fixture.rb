module Skiptrace
  module CustomErrorFixture
    Error = Class.new(StandardError)

    def self.call
      raise Error
    rescue => exc
      exc
    end
  end
end
