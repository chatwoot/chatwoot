# frozen_string_literal: true

module Stripe
  module EventTypes
    def self.v2_event_types_to_classes
      {
        # v2 event types: The beginning of the section generated from our OpenAPI spec
        Events::V1BillingMeterErrorReportTriggeredEvent.lookup_type =>
        Events::V1BillingMeterErrorReportTriggeredEvent,
        Events::V1BillingMeterNoMeterFoundEvent.lookup_type => Events::V1BillingMeterNoMeterFoundEvent,
        Events::V2CoreEventDestinationPingEvent.lookup_type => Events::V2CoreEventDestinationPingEvent,
        # v2 event types: The end of the section generated from our OpenAPI spec
      }
    end

    def self.event_notification_types_to_classes
      {
        # event notification types: The beginning of the section generated from our OpenAPI spec
        Events::V1BillingMeterErrorReportTriggeredEventNotification.lookup_type =>
        Events::V1BillingMeterErrorReportTriggeredEventNotification,
        Events::V1BillingMeterNoMeterFoundEventNotification.lookup_type =>
        Events::V1BillingMeterNoMeterFoundEventNotification,
        Events::V2CoreEventDestinationPingEventNotification.lookup_type =>
        Events::V2CoreEventDestinationPingEventNotification,
        # event notification types: The end of the section generated from our OpenAPI spec
      }
    end
  end
end
