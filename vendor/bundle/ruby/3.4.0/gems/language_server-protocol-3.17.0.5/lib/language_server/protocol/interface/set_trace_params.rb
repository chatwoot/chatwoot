module LanguageServer
  module Protocol
    module Interface
      class SetTraceParams
        def initialize(value:)
          @attributes = {}

          @attributes[:value] = value

          @attributes.freeze
        end

        #
        # The new value that should be assigned to the trace setting.
        #
        # @return [TraceValue]
        def value
          attributes.fetch(:value)
        end

        attr_reader :attributes

        def to_hash
          attributes
        end

        def to_json(*args)
          to_hash.to_json(*args)
        end
      end
    end
  end
end
