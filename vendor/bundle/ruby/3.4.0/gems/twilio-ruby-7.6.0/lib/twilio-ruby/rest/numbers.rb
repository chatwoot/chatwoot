module Twilio
  module REST
    class Numbers < NumbersBase
      ##
      # @return [Twilio::REST::Numbers::V2::RegulatoryComplianceInstance]
      def regulatory_compliance
        warn "regulatory_compliance is deprecated. Use v2.regulatory_compliance instead."
        self.v2.regulatory_compliance()
      end
    end
  end
end