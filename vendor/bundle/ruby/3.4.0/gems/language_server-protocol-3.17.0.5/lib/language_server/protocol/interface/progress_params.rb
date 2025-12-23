module LanguageServer
  module Protocol
    module Interface
      class ProgressParams
        def initialize(token:, value:)
          @attributes = {}

          @attributes[:token] = token
          @attributes[:value] = value

          @attributes.freeze
        end

        #
        # The progress token provided by the client or server.
        #
        # @return [ProgressToken]
        def token
          attributes.fetch(:token)
        end

        #
        # The progress data.
        #
        # @return [T]
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
