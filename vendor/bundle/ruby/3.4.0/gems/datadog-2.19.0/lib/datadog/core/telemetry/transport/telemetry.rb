# frozen_string_literal: true

require_relative '../../transport/parcel'
require_relative 'http/client'
require_relative 'http/telemetry'

module Datadog
  module Core
    module Telemetry
      module Transport
        module Telemetry
          class EncodedParcel
            include Datadog::Core::Transport::Parcel
          end

          class Request < Datadog::Core::Transport::Request
            attr_reader :request_type
            attr_reader :api_key

            def initialize(request_type, parcel, api_key)
              @request_type = request_type
              super(parcel)
              @api_key = api_key
            end
          end

          class Transport
            attr_reader :client, :apis, :default_api, :current_api_id, :logger
            attr_accessor :api_key

            def initialize(apis, default_api, logger:)
              @apis = apis
              @logger = logger

              @client = HTTP::Client.new(@apis[default_api], logger: logger)
            end

            def send_telemetry(request_type:, payload:)
              json = JSON.dump(payload)
              parcel = EncodedParcel.new(json)
              request = Request.new(request_type, parcel, api_key)

              @client.send_telemetry_payload(request)
              # Perform no error checking here
            end
          end
        end
      end
    end
  end
end
