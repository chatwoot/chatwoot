module Twilio
  module REST
    class Routes < RoutesBase
      ##
      # @param [String] phone_number The phone number in E.164 format
      # @return [Twilio::REST::Routes::V2::PhoneNumberInstance] if phone_number was passed.
      # @return [Twilio::REST::Routes::V2::PhoneNumberList]
      def phone_numbers(phone_number=:unset)
        warn "phone_numbers is deprecated. Use v2.phone_numbers instead."
        self.v2.phone_numbers(phone_number)
      end

      ##
      # @param [String] sip_domain The sip_domain
      # @return [Twilio::REST::Routes::V2::SipDomainInstance] if sip_domain was passed.
      # @return [Twilio::REST::Routes::V2::SipDomainList]
      def sip_domains(sip_domain=:unset)
        warn "sip_domains is deprecated. Use v2.sip_domains instead."
        self.v2.sip_domains(sip_domain)
      end

      ##
      # @param [String] sip_trunk_domain The absolute URL of the SIP Trunk
      # @return [Twilio::REST::Routes::V2::TrunkInstance] if sip_trunk_domain was passed.
      # @return [Twilio::REST::Routes::V2::TrunkList]
      def trunks(sip_trunk_domain=:unset)
        warn "trunks is deprecated. Use v2.trunks instead."
        self.v2.trunks(sip_trunk_domain)
      end
    end
  end
end