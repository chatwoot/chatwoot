# Mexico phone numbers can appear with or without "1" after country code for mobile numbers
# This normalizer removes the "1" when present to create consistent format: 52 + area + number
class Whatsapp::PhoneNormalizers::MexicoPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  def normalize(waid)
    return waid unless handles_country?(waid)

    # Remove "1" after country code if present (521 → 52)
    waid.sub(/^521/, '52')
  end

  private

  def country_code_pattern
    /^52/
  end
end