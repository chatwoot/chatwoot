# Handles Brazil phone number normalization
# ref: https://github.com/chatwoot/chatwoot/issues/5840
# ref: https://www.gov.br/anatel/pt-br/regulado/numeracao/perguntas-frequentes
#
# Brazil changed its mobile number system by adding a "9" prefix to existing numbers.
# This normalizer adds the "9" only to legacy eight-digit mobile ranges, leaving
# eight-digit landlines (which start with 2-5) unchanged.
class Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  COUNTRY_CODE_LENGTH = 2
  DDD_LENGTH = 2
  LEGACY_MOBILE_NUMBER_PATTERN = /\A[6-9]\d{7}\z/
  CANONICAL_MOBILE_NUMBER_PATTERN = /\A9([6-9]\d{7})\z/

  def normalize(waid)
    return waid unless handles_country?(waid)

    ddd = waid[COUNTRY_CODE_LENGTH, DDD_LENGTH]
    number = subscriber(waid)
    return waid unless number.match?(LEGACY_MOBILE_NUMBER_PATTERN)

    "55#{ddd}9#{number}"
  end

  def variants(waid)
    normalized = normalize(waid)
    [normalized, legacy_mobile_form(normalized)].compact.uniq
  end

  def contact_candidates(waid)
    [waid, *variants(waid)].uniq
  end

  private

  # Mirror of #normalize: strip the 9 only when what remains is itself a legacy mobile range, never a landline.
  def legacy_mobile_form(waid)
    return unless handles_country?(waid)

    match = subscriber(waid).match(CANONICAL_MOBILE_NUMBER_PATTERN)
    return if match.nil?

    "55#{waid[COUNTRY_CODE_LENGTH, DDD_LENGTH]}#{match[1]}"
  end

  def subscriber(waid)
    waid[(COUNTRY_CODE_LENGTH + DDD_LENGTH)..].to_s
  end

  def country_code_pattern
    /^55/
  end
end
