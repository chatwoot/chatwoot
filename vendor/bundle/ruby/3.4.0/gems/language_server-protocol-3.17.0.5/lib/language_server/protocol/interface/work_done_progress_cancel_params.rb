module LanguageServer
  module Protocol
    module Interface
      class WorkDoneProgressCancelParams
        def initialize(token:)
          @attributes = {}

          @attributes[:token] = token

          @attributes.freeze
        end

        #
        # The token to be used to report progress.
        #
        # @return [ProgressToken]
        def token
          attributes.fetch(:token)
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
