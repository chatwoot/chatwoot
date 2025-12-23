module LanguageServer
  module Protocol
    module Interface
      #
      # A previous result id in a workspace pull request.
      #
      class PreviousResultId
        def initialize(uri:, value:)
          @attributes = {}

          @attributes[:uri] = uri
          @attributes[:value] = value

          @attributes.freeze
        end

        #
        # The URI for which the client knows a
        # result id.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # The value of the previous result id.
        #
        # @return [string]
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
