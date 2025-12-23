module Twilio
  module REST
    class Studio < StudioBase
      ##
      # @param [String] sid The unique string that we created to identify the Flow
      #   resource.
      # @return [Twilio::REST::Studio::V2::FlowInstance] if sid was passed.
      # @return [Twilio::REST::Studio::V2::FlowList]
      def flows(sid=:unset)
        warn "flows is deprecated. Use v2.flows instead."
        self.v2.flows(sid)
      end

      ##
      # @return [Twilio::REST::Studio::V2::FlowValidateInstance]
      def flow_validate
        warn "flow_validate is deprecated. Use v2.flow_validate instead."
        self.v2.flow_validate()
      end
    end
  end
end