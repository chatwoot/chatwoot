# frozen_string_literal: true

require_relative '../../core/transport/parcel'
require_relative 'http/client'

module Datadog
  module DI
    module Transport
      module Input
        class EncodedParcel
          include Datadog::Core::Transport::Parcel
        end

        class Request < Datadog::Core::Transport::Request
          attr_reader :serialized_tags

          def initialize(parcel, serialized_tags)
            super(parcel)

            @serialized_tags = serialized_tags
          end
        end

        class Transport
          attr_reader :client, :apis, :default_api, :current_api_id, :logger

          def initialize(apis, default_api, logger:)
            @apis = apis
            @logger = logger

            @client = HTTP::Client.new(current_api, logger: logger)
          end

          def current_api
            @apis[HTTP::API::INPUT]
          end

          def send_input(payload, tags)
            json = JSON.dump(payload)
            parcel = EncodedParcel.new(json)
            serialized_tags = Core::TagBuilder.serialize_tags(tags)
            request = Request.new(parcel, serialized_tags)

            response = @client.send_input_payload(request)
            unless response.ok?
              # TODO Datadog::Core::Transport::InternalErrorResponse
              # does not have +code+ method, what is the actual API of
              # these response objects?
              raise Error::AgentCommunicationError, "send_input failed: #{begin
                response.code
              rescue
                "???"
              end}: #{response.payload}"
            end
          rescue Error::AgentCommunicationError
            raise
          # Datadog::Core::Transport does not perform any exception mapping,
          # therefore we could have any exception here from failure to parse
          # agent URI for example.
          # If we ever implement retries for network errors, we should distinguish
          # actual network errors from non-network errors that are raised by
          # transport code.
          rescue => exc
            raise Error::AgentCommunicationError, "send_input failed: #{exc.class}: #{exc}"
          end
        end
      end
    end
  end
end
