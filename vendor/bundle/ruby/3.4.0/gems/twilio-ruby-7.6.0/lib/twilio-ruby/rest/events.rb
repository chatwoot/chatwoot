module Twilio
  module REST
    class Events < EventsBase
      ##
      # @param [String] type A string that uniquely identifies this Event Type.
      # @return [Twilio::REST::Events::V1::EventTypeInstance] if type was passed.
      # @return [Twilio::REST::Events::V1::EventTypeList]
      def event_types(type=:unset)
        warn "event_types is deprecated. Use v1.event_types instead."
        self.v1.event_types(type)
      end

      ##
      # @param [String] id The unique identifier of the schema. Each schema can have
      #   multiple versions, that share the same id.
      # @return [Twilio::REST::Events::V1::SchemaInstance] if id was passed.
      # @return [Twilio::REST::Events::V1::SchemaList]
      def schemas(id=:unset)
        warn "schemas is deprecated. Use v1.schemas instead."
        self.v1.schemas(id)
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this Sink.
      # @return [Twilio::REST::Events::V1::SinkInstance] if sid was passed.
      # @return [Twilio::REST::Events::V1::SinkList]
      def sinks(sid=:unset)
        warn "sinks is deprecated. Use v1.sinks instead."
        self.v1.sinks(sid)
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   Subscription.
      # @return [Twilio::REST::Events::V1::SubscriptionInstance] if sid was passed.
      # @return [Twilio::REST::Events::V1::SubscriptionList]
      def subscriptions(sid=:unset)
        warn "subscriptions is deprecated. Use v1.subscriptions instead."
        self.v1.subscriptions(sid)
      end
    end
  end
end