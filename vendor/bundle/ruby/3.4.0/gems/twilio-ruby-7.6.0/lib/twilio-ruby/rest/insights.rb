module Twilio
  module REST
    class Insights < InsightsBase
      ##
      # @return [Twilio::REST::Insights::V1::SettingInstance]
      def settings
        warn "settings is deprecated. Use v1.settings instead."
        self.v1.settings()
      end

      ##
      # @param [String] sid The sid
      # @return [Twilio::REST::Insights::V1::CallInstance] if sid was passed.
      # @return [Twilio::REST::Insights::V1::CallList]
      def calls(sid=:unset)
        warn "calls is deprecated. Use v1.calls instead."
        self.v1.calls(sid)
      end

      ##
      # @return [Twilio::REST::Insights::V1::CallSummariesInstance]
      def call_summaries
        warn "call_summaries is deprecated. Use v1.call_summaries instead."
        self.v1.call_summaries()
      end

      ##
      # @param [String] conference_sid The unique SID identifier of the Conference.
      # @return [Twilio::REST::Insights::V1::ConferenceInstance] if conference_sid was passed.
      # @return [Twilio::REST::Insights::V1::ConferenceList]
      def conferences(conference_sid=:unset)
        warn "conferences is deprecated. Use v1.conferences instead."
        self.v1.conferences(conference_sid)
      end

      ##
      # @param [String] room_sid Unique identifier for the room.
      # @return [Twilio::REST::Insights::V1::RoomInstance] if room_sid was passed.
      # @return [Twilio::REST::Insights::V1::RoomList]
      def rooms(room_sid=:unset)
        warn "rooms is deprecated. Use v1.rooms instead."
        self.v1.rooms(room_sid)
      end
    end
  end
end