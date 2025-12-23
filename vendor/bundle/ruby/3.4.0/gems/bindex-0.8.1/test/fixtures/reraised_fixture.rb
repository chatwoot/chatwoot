module Skiptrace
  module ReraisedFixture
    extend self

    def call
      reraise_an_error
    rescue => exc
      exc
    end

    private

    def raise_an_error_in_eval
      method_that_raises
    rescue => exc
      raise exc
    end

    def method_that_raises
      raise
    end
  end
end
