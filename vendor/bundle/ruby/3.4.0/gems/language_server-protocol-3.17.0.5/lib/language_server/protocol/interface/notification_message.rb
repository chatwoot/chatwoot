module LanguageServer
  module Protocol
    module Interface
      class NotificationMessage
        def initialize(jsonrpc:, method:, params: nil)
          @attributes = {}

          @attributes[:jsonrpc] = jsonrpc
          @attributes[:method] = method
          @attributes[:params] = params if params

          @attributes.freeze
        end

        # @return [string]
        def jsonrpc
          attributes.fetch(:jsonrpc)
        end

        #
        # The method to be invoked.
        #
        # @return [string]
        def method
          attributes.fetch(:method)
        end

        #
        # The notification's params.
        #
        # @return [any]
        def params
          attributes.fetch(:params)
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
