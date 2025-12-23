module LanguageServer
  module Protocol
    module Interface
      #
      # Static registration options to be returned in the initialize request.
      #
      class StaticRegistrationOptions
        def initialize(id: nil)
          @attributes = {}

          @attributes[:id] = id if id

          @attributes.freeze
        end

        #
        # The id used to register the request. The id can be used to deregister
        # the request again. See also Registration#id.
        #
        # @return [string]
        def id
          attributes.fetch(:id)
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
