module Shoulda
  module Matchers
    module Doublespeak
      # @private
      class StubImplementation
        DoubleImplementationRegistry.register(self, :stub)

        def self.create
          new
        end

        def initialize
          @implementation = proc { nil }
        end

        def returns(value = nil, &block)
          @implementation = block || proc { value }
        end

        def call(call)
          call.double.record_call(call)
          implementation.call(call)
        end

        protected

        attr_reader :implementation
      end
    end
  end
end
