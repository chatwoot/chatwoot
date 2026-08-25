# Handles Mexico phone number normalization
#
# WhatsApp may include a "1" after Mexico's country code (521), while contacts
# can already be stored without it (52). Normalize to the stored WAID (digits-only)
# format; provider formatting (whatsapp:+...) happens in the normalization service.
# The mobile "1" only appears on the 13-digit form (52 + 1 + 10 digits), so guard
# on length to avoid stripping a legitimate "1" from a shorter national number.
class Whatsapp::PhoneNormalizers::MexicoPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  COUNTRY_CODE_WITH_MOBILE_LENGTH = 13

  def normalize(waid)
    return waid unless handles_country?(waid)
    return waid unless waid.length == COUNTRY_CODE_WITH_MOBILE_LENGTH

    waid.sub(/^521/, '52')
  end

  private

  def country_code_pattern
    /^52/
  end
end
