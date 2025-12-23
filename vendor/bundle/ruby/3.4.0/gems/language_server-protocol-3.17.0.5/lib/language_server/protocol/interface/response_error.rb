module LanguageServer
  module Protocol
    module Interface
      class ResponseError
        def initialize(code:, message:, data: nil)
          @attributes = {}

          @attributes[:code] = code
          @attributes[:message] = message
          @attributes[:data] = data if data

          @attributes.freeze
        end

        #
        # A number indicating the error type that occurred.
        #
        # @return [number]
        def code
          attributes.fetch(:code)
        end

        #
        # A string providing a short description of the error.
        #
        # @return [string]
        def message
          attributes.fetch(:message)
        end

        #
        # A primitive or structured value that contains additional
        # information about the error. Can be omitted.
        #
        # @return [any]
        def data
          attributes.fetch(:data)
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
