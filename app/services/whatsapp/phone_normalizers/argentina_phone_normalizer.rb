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

  # Deliberately no #variants override: 549 and 54 are not two spellings of one subscriber the
  # way Brazil's ninth digit is. Dropping the 9 yields a valid landline in the same area code, so
  # offering it as an alternate can answer as a different customer's conversation.

  private

  def country_code_pattern
    /^54/
  end
end
