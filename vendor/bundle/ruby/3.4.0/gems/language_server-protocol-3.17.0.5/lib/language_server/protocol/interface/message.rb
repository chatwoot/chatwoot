module LanguageServer
  module Protocol
    module Interface
      class Message
        def initialize(jsonrpc:)
          @attributes = {}

          @attributes[:jsonrpc] = jsonrpc

          @attributes.freeze
        end

        # @return [string]
        def jsonrpc
          attributes.fetch(:jsonrpc)
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
