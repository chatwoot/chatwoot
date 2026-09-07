# Handles Argentina phone number normalization
#
# Argentina phone numbers can appear with or without "9" after country code
# This normalizer removes the "9" when present to create consistent format: 54 + area + number
class Whatsapp::PhoneNormalizers::ArgentinaPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  NATIONAL_NUMBER_LENGTH = 12

  def normalize(waid)
    return waid unless handles_country?(waid)

    # Remove "9" after country code if present (549 → 54)
    waid.sub(/^549/, '54')
  end

  # Symmetric on purpose: #normalize already answers 549 into a stored 54 thread, so the reverse only avoids a duplicate.
  def variants(waid)
    normalized = normalize(waid)
    return [normalized] unless normalized.length == NATIONAL_NUMBER_LENGTH

    [normalized, normalized.sub(/^54/, '549')]
  end

  private

  def country_code_pattern
    /^54/
  end
end
