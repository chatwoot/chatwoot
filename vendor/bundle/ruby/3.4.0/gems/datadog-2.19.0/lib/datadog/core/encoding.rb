# frozen_string_literal: true

require 'json'
require 'msgpack'

module Datadog
  module Core
    # Encoding module that encodes data for the AgentTransport
    module Encoding
      # Encoder interface that provides the logic to encode traces and service
      # @abstract
      module Encoder
        # :nocov:
        def content_type
          raise NotImplementedError
        end

        # Concatenates a list of elements previously encoded by +#encode+.
        def join(encoded_elements)
          raise NotImplementedError
        end

        # Serializes a single trace into a String suitable for network transmission.
        def encode(_)
          raise NotImplementedError
        end

        # Deserializes a value serialized with {#encode}.
        # This method is used for debugging purposes.
        def decode(_)
          raise NotImplementedError
        end
        # :nocov:
      end

      # Encoder for the JSON format
      module JSONEncoder
        extend Encoder

        CONTENT_TYPE = 'application/json'

        module_function

        def content_type
          CONTENT_TYPE
        end

        def encode(obj)
          JSON.dump(obj)
        end

        def decode(obj)
          JSON.parse(obj)
        end

        def join(encoded_data)
          "[#{encoded_data.join(",")}]"
        end
      end

      # Encoder for the Msgpack format
      module MsgpackEncoder
        extend Encoder

        module_function

        CONTENT_TYPE = 'application/msgpack'

        def content_type
          CONTENT_TYPE
        end

        def encode(obj)
          MessagePack.pack(obj)
        end

        def decode(obj)
          MessagePack.unpack(obj)
        end

        def join(encoded_data)
          packer = MessagePack::Packer.new
          packer.write_array_header(encoded_data.size)

          (packer.buffer.to_a + encoded_data).join
        end
      end
    end
  end
end
