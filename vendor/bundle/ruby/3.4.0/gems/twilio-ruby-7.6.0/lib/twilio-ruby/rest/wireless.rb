module Twilio
  module REST
    class Wireless < WirelessBase
      ##
      # @return [Twilio::REST::Wireless::V1::UsageRecordInstance]
      def usage_records
        warn "usage_records is deprecated. Use v1.usage_records instead."
        self.v1.usage_records()
      end

      ##
      # @param [String] sid The unique string that we created to identify the Command
      #   resource.
      # @return [Twilio::REST::Wireless::V1::CommandInstance] if sid was passed.
      # @return [Twilio::REST::Wireless::V1::CommandList]
      def commands(sid=:unset)
        warn "commands is deprecated. Use v1.commands instead."
        self.v1.commands(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the RatePlan
      #   resource.
      # @return [Twilio::REST::Wireless::V1::RatePlanInstance] if sid was passed.
      # @return [Twilio::REST::Wireless::V1::RatePlanList]
      def rate_plans(sid=:unset)
        warn "rate_plans is deprecated. Use v1.rate_plans instead."
        self.v1.rate_plans(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Sim
      #   resource.
      # @return [Twilio::REST::Wireless::V1::SimInstance] if sid was passed.
      # @return [Twilio::REST::Wireless::V1::SimList]
      def sims(sid=:unset)
        warn "sims is deprecated. Use v1.sims instead."
        self.v1.sims(sid)
      end
    end
  end
end