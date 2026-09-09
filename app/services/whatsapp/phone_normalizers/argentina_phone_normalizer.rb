# Handles Argentina phone number normalization
#
# Argentina phone numbers can appear with or without "9" after country code
# This normalizer removes the "9" when present to create consistent format: 54 + area + number
class Whatsapp::PhoneNormalizers::ArgentinaPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  def normalize(waid)
    return waid unless handles_country?(waid)

    # Remove "9" after country code if present (549 → 54)
    waid.sub(/^549/, '54')
  end

  # No #variants override: a 54 number without the 9 is a valid landline, so a synthesized 549 alias can answer as a different subscriber.

  private

  def country_code_pattern
    /^54/
  end
end
