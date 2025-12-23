module Twilio
  module REST
    class Lookups < LookupsBase
      ##
      # @param [String] phone_number The phone number in
      #   {E.164}[https://www.twilio.com/docs/glossary/what-e164] format, which consists
      #   of a + followed by the country code and subscriber number.
      # @return [Twilio::REST::Lookups::V1::PhoneNumberInstance] if phone_number was passed.
      # @return [Twilio::REST::Lookups::V1::PhoneNumberList]
      def phone_numbers(phone_number=:unset)
        warn "phone_numbers is deprecated. Use v1.phone_numbers instead."
        self.v1.phone_numbers(phone_number)
      end
    end
  end
end