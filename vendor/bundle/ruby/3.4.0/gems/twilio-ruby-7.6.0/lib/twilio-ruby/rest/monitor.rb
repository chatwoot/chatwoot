module Twilio
  module REST
    class Monitor < MonitorBase
      ##
      # @param [String] sid The unique string that we created to identify the Alert
      #   resource.
      # @return [Twilio::REST::Monitor::V1::AlertInstance] if sid was passed.
      # @return [Twilio::REST::Monitor::V1::AlertList]
      def alerts(sid=:unset)
        warn "alerts is deprecated. Use v1.alerts instead."
        self.v1.alerts(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Event
      #   resource.
      # @return [Twilio::REST::Monitor::V1::EventInstance] if sid was passed.
      # @return [Twilio::REST::Monitor::V1::EventList]
      def events(sid=:unset)
        warn "events is deprecated. Use v1.events instead."
        self.v1.events(sid)
      end
    end
  end
end