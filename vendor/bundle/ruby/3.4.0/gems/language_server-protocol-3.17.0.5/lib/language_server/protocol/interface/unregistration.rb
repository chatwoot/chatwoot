module LanguageServer
  module Protocol
    module Interface
      #
      # General parameters to unregister a capability.
      #
      class Unregistration
        def initialize(id:, method:)
          @attributes = {}

          @attributes[:id] = id
          @attributes[:method] = method

          @attributes.freeze
        end

        #
        # The id used to unregister the request or notification. Usually an id
        # provided during the register request.
        #
        # @return [string]
        def id
          attributes.fetch(:id)
        end

        #
        # The method / capability to unregister for.
        #
        # @return [string]
        def method
          attributes.fetch(:method)
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
