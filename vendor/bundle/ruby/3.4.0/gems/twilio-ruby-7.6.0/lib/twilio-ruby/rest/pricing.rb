module Twilio
  module REST
    class Pricing < PricingBase
      ##
      # @return [Twilio::REST::Pricing::V1::MessagingInstance]
      def messaging
        warn "messaging is deprecated. Use v1.messaging instead."
        self.v1.messaging()
      end

      ##
      # @return [Twilio::REST::Pricing::V1::PhoneNumberInstance]
      def phone_numbers
        warn "phone_numbers is deprecated. Use v1.phone_numbers instead."
        self.v1.phone_numbers()
      end

      ##
      # @return [Twilio::REST::Pricing::V2::VoiceInstance]
      def voice
        warn "voice is deprecated. Use v2.voice instead."
        self.v2.voice()
      end

      ##
      # @param [String] iso_country The {ISO country
      #   code}[https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2].
      # @return [Twilio::REST::Pricing::V2::CountryInstance] if iso_country was passed.
      # @return [Twilio::REST::Pricing::V2::CountryList]
      def countries(iso_country=:unset)
        warn "countries is deprecated. Use v2.countries instead."
        self.v2.countries(iso_country)
      end

      ##
      # @param [String] destination_number The destination phone number in
      #   {E.164}[https://www.twilio.com/docs/glossary/what-e164] format, which consists
      #   of a + followed by the country code and subscriber number.
      # @return [Twilio::REST::Pricing::V2::NumberInstance] if destination_number was passed.
      # @return [Twilio::REST::Pricing::V2::NumberList]
      def numbers(destination_number=:unset)
        warn "numbers is deprecated. Use v2.numbers instead."
        self.v2.numbers(destination_number)
      end
    end
  end
end