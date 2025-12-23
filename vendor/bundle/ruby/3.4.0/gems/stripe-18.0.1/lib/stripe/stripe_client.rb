# frozen_string_literal: true

require "json"
require "stripe/events/unknown_event_notification"

module Stripe
  class StripeClient
    # attr_readers: The beginning of the section generated from our OpenAPI spec
    attr_reader :v1
    attr_reader :v2

    # attr_readers: The end of the section generated from our OpenAPI spec

    # For internal use only. Does not provide a stable API and may be broken
    # with future non-major changes.
    CLIENT_OPTIONS = Set.new(%i[api_key stripe_account stripe_context api_version api_base uploads_base connect_base meter_events_base client_id])

    # Initializes a new StripeClient
    def initialize(api_key,
                   stripe_account: nil,
                   stripe_context: nil,
                   stripe_version: nil,
                   api_base: nil,
                   uploads_base: nil,
                   connect_base: nil,
                   meter_events_base: nil,
                   client_id: nil)
      unless api_key
        raise AuthenticationError, "No API key provided. " \
                                   'Set your API key using "client = Stripe::StripeClient.new(<API-KEY>)". ' \
                                   "You can generate API keys from the Stripe web interface. " \
                                   "See https://stripe.com/api for details, or email " \
                                   "support@stripe.com if you have any questions."
      end

      config_opts = {
        api_key: api_key,
        stripe_account: stripe_account,
        stripe_context: stripe_context,
        api_version: stripe_version,
        api_base: api_base,
        uploads_base: uploads_base,
        connect_base: connect_base,
        meter_events_base: meter_events_base,
        client_id: client_id,
      }.compact

      config = StripeConfiguration.client_init(config_opts)
      @requestor = APIRequestor.new(config)

      # top-level services: The beginning of the section generated from our OpenAPI spec
      @v1 = Stripe::V1Services.new(@requestor)
      @v2 = Stripe::V2Services.new(@requestor)
      # top-level services: The end of the section generated from our OpenAPI spec
    end

    def request(&block)
      @requestor.request(&block)
    end
    extend Gem::Deprecate
    deprecate :request, :raw_request, 2024, 9

    def parse_event_notification(payload, sig_header, secret, tolerance: Webhook::DEFAULT_TOLERANCE)
      payload = payload.force_encoding("UTF-8") if payload.respond_to?(:force_encoding)

      # v2 events use the same signing mechanism as v1 events
      Webhook::Signature.verify_header(payload, sig_header, secret, tolerance: tolerance)

      parsed = JSON.parse(payload, symbolize_names: true)

      cls = Util.event_notification_classes.fetch(parsed[:type], Stripe::Events::UnknownEventNotification)

      cls.new(parsed, self)
    end

    def raw_request(method, url, base_address: :api, params: {}, opts: {}, usage: nil)
      opts = Util.normalize_opts(opts)
      req_opts = RequestOptions.extract_opts_from_hash(opts)

      params = params.to_h if params.is_a?(Stripe::RequestParams)
      resp, = @requestor.send(:execute_request_internal, method, url, base_address, params, req_opts, usage: usage || ["raw_request"])

      @requestor.interpret_response(resp)
    end

    def deserialize(data, api_mode: :v1)
      data = JSON.parse(data) if data.is_a?(String)
      Util.convert_to_stripe_object(data, {}, api_mode: api_mode, requestor: @requestor)
    end
  end
end
