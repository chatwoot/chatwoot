module Datadog
  module AppSec
    module WAF
      Error = Class.new(StandardError)
      InstanceFinalizedError = Class.new(Error)
      ConversionError = Class.new(Error)

      class LibDDWAFError < Error
        attr_reader :diagnostics

        def initialize(msg, diagnostics: nil)
          @diagnostics = diagnostics

          super(msg)
        end
      end
    end
  end
end
