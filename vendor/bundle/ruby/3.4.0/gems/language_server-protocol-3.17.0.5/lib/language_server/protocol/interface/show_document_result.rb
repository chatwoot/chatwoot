module LanguageServer
  module Protocol
    module Interface
      #
      # The result of an show document request.
      #
      class ShowDocumentResult
        def initialize(success:)
          @attributes = {}

          @attributes[:success] = success

          @attributes.freeze
        end

        #
        # A boolean indicating if the show was successful.
        #
        # @return [boolean]
        def success
          attributes.fetch(:success)
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
