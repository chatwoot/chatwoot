module Twilio
  module REST
    class Trunking < TrunkingBase
      ##
      # @param [String] sid The unique string that we created to identify the Trunk
      #   resource.
      # @return [Twilio::REST::Trunking::V1::TrunkInstance] if sid was passed.
      # @return [Twilio::REST::Trunking::V1::TrunkList]
      def trunks(sid=:unset)
        warn "trunks is deprecated. Use v1.trunks instead."
        self.v1.trunks(sid)
      end
    end
  end
end