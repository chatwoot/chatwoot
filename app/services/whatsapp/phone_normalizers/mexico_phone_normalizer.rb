# Handles Mexico phone number normalization
#
# WhatsApp may include a "1" after Mexico's country code (521), while contacts
# can already be stored without it (52). Normalize to the stored E.164 format.
class Whatsapp::PhoneNormalizers::MexicoPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  def normalize(waid)
    return waid unless handles_country?(waid)

    waid.sub(/^521/, '52')
  end

  private

  def country_code_pattern
    /^52/
  end
end
