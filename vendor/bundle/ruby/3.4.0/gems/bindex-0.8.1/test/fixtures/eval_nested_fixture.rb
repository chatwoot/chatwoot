module Skiptrace
  module EvalNestedFixture
    extend self

    def call
      tap { raise_an_error_in_eval }
    rescue => exc
      exc
    end

    private

    def raise_an_error_in_eval
      eval 'raise', binding, __FILE__, __LINE__
    end
  end
end
