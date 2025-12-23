# frozen_string_literal: true

require "json"
require "sentry/envelope"

module Sentry
  class Transport
    PROTOCOL_VERSION = '7'
    USER_AGENT = "sentry-ruby/#{Sentry::VERSION}"
    CLIENT_REPORT_INTERVAL = 30

    # https://develop.sentry.dev/sdk/client-reports/#envelope-item-payload
    CLIENT_REPORT_REASONS = [
      :ratelimit_backoff,
      :queue_overflow,
      :cache_overflow, # NA
      :network_error,
      :sample_rate,
      :before_send,
      :event_processor,
      :insufficient_data,
      :backpressure
    ]

    include LoggingHelper

    attr_reader :rate_limits, :discarded_events, :last_client_report_sent

    # @deprecated Use Sentry.logger to retrieve the current logger instead.
    attr_reader :logger

    def initialize(configuration)
      @logger = configuration.logger
      @transport_configuration = configuration.transport
      @dsn = configuration.dsn
      @rate_limits = {}
      @send_client_reports = configuration.send_client_reports

      if @send_client_reports
        @discarded_events = Hash.new(0)
        @last_client_report_sent = Time.now
      end
    end

    def send_data(data, options = {})
      raise NotImplementedError
    end

    def send_event(event)
      envelope = envelope_from_event(event)
      send_envelope(envelope)

      event
    end

    def send_envelope(envelope)
      reject_rate_limited_items(envelope)

      return if envelope.items.empty?

      data, serialized_items = serialize_envelope(envelope)

      if data
        log_debug("[Transport] Sending envelope with items [#{serialized_items.map(&:type).join(', ')}] #{envelope.event_id} to Sentry")
        send_data(data)
      end
    end

    def serialize_envelope(envelope)
      serialized_items = []
      serialized_results = []

      envelope.items.each do |item|
        result, oversized = item.serialize

        if oversized
          log_debug("Envelope item [#{item.type}] is still oversized after size reduction: {#{item.size_breakdown}}")

          next
        end

        serialized_results << result
        serialized_items << item
      end

      data = [JSON.generate(envelope.headers), *serialized_results].join("\n") unless serialized_results.empty?

      [data, serialized_items]
    end

    def is_rate_limited?(data_category)
      # check category-specific limit
      category_delay = @rate_limits[data_category]
      # check universal limit if not category limit
      universal_delay = @rate_limits[nil]

      delay =
        if category_delay && universal_delay
          if category_delay > universal_delay
            category_delay
          else
            universal_delay
          end
        elsif category_delay
          category_delay
        else
          universal_delay
        end

      !!delay && delay > Time.now
    end

    def any_rate_limited?
      @rate_limits.values.any? { |t| t && t > Time.now }
    end

    def envelope_from_event(event)
      # Convert to hash
      event_payload = event.to_hash
      event_id = event_payload[:event_id] || event_payload["event_id"]
      item_type = event_payload[:type] || event_payload["type"]

      envelope_headers = {
        event_id: event_id,
        dsn: @dsn.to_s,
        sdk: Sentry.sdk_meta,
        sent_at: Sentry.utc_now.iso8601
      }

      if event.is_a?(Event) && event.dynamic_sampling_context
        envelope_headers[:trace] = event.dynamic_sampling_context
      end

      envelope = Envelope.new(envelope_headers)

      envelope.add_item(
        { type: item_type, content_type: 'application/json' },
        event_payload
      )

      if event.is_a?(TransactionEvent) && event.profile
        envelope.add_item(
          { type: 'profile', content_type: 'application/json' },
          event.profile
        )
      end

      if event.is_a?(Event) && event.attachments.any?
        event.attachments.each do |attachment|
          envelope.add_item(attachment.to_envelope_headers, attachment.payload)
        end
      end

      client_report_headers, client_report_payload = fetch_pending_client_report
      envelope.add_item(client_report_headers, client_report_payload) if client_report_headers

      envelope
    end

    def record_lost_event(reason, data_category, num: 1)
      return unless @send_client_reports
      return unless CLIENT_REPORT_REASONS.include?(reason)

      @discarded_events[[reason, data_category]] += num
    end

    def flush
      client_report_headers, client_report_payload = fetch_pending_client_report(force: true)
      return unless client_report_headers

      envelope = Envelope.new
      envelope.add_item(client_report_headers, client_report_payload)
      send_envelope(envelope)
    end

    private

    def fetch_pending_client_report(force: false)
      return nil unless @send_client_reports
      return nil if !force && @last_client_report_sent > Time.now - CLIENT_REPORT_INTERVAL
      return nil if @discarded_events.empty?

      discarded_events_hash = @discarded_events.map do |key, val|
        reason, category = key
        { reason: reason, category: category, quantity: val }
      end

      item_header = { type: 'client_report' }
      item_payload = {
        timestamp: Sentry.utc_now.iso8601,
        discarded_events: discarded_events_hash
      }

      @discarded_events = Hash.new(0)
      @last_client_report_sent = Time.now

      [item_header, item_payload]
    end

    def reject_rate_limited_items(envelope)
      envelope.items.reject! do |item|
        if is_rate_limited?(item.data_category)
          log_debug("[Transport] Envelope item [#{item.type}] not sent: rate limiting")
          record_lost_event(:ratelimit_backoff, item.data_category)

          true
        else
          false
        end
      end
    end
  end
end

require "sentry/transport/dummy_transport"
require "sentry/transport/http_transport"
require "sentry/transport/spotlight_transport"
