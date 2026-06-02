# Handles Brazil phone number normalization
# ref: https://github.com/chatwoot/chatwoot/issues/5840
#
# Brazil changed its mobile number system by adding a "9" prefix to existing numbers.
# This normalizer adds the "9" digit if the number is 12 digits (making it 13 digits total)
# to match the new format: 55 + DDD + 9 + number
class Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  COUNTRY_CODE_LENGTH = 2
  DDD_LENGTH = 2

  def normalize(waid)
    return waid unless handles_country?(waid)

    ddd = waid[COUNTRY_CODE_LENGTH, DDD_LENGTH]
    number = waid[COUNTRY_CODE_LENGTH + DDD_LENGTH, waid.length - (COUNTRY_CODE_LENGTH + DDD_LENGTH)]
    normalized_number = "55#{ddd}#{number}"
    normalized_number = "55#{ddd}9#{number}" if normalized_number.length != 13
    normalized_number
  end

  private

  def country_code_pattern
    /^55/
  end
end
