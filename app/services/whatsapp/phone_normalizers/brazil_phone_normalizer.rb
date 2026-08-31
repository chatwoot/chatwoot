# Handles Brazil phone number normalization
# ref: https://github.com/chatwoot/chatwoot/issues/5840
#
# Brazil changed its mobile number system by adding a "9" prefix to existing numbers.
# This normalizer adds the "9" digit if the number is 12 digits (making it 13 digits total)
# to match the new format: 55 + DDD + 9 + number
class Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  COUNTRY_CODE_LENGTH = 2
  DDD_LENGTH = 2
  MOBILE_DIGIT_INDEX = COUNTRY_CODE_LENGTH + DDD_LENGTH
  MOBILE_LENGTH = 13

  def normalize(waid)
    return waid unless handles_country?(waid)

    ddd = waid[COUNTRY_CODE_LENGTH, DDD_LENGTH]
    number = waid[MOBILE_DIGIT_INDEX, waid.length - MOBILE_DIGIT_INDEX]
    normalized_number = "55#{ddd}#{number}"
    normalized_number = "55#{ddd}9#{number}" if normalized_number.length != MOBILE_LENGTH
    normalized_number
  end

  # Contacts may already be stored without the "9", so look that format up too
  def variants(waid)
    normalized = normalize(waid)
    return [normalized] unless normalized.length == MOBILE_LENGTH && normalized[MOBILE_DIGIT_INDEX] == '9'

    [normalized, "#{normalized[0, MOBILE_DIGIT_INDEX]}#{normalized[(MOBILE_DIGIT_INDEX + 1)..]}"]
  end

  private

  def country_code_pattern
    /^55/
  end
end
