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

  def contact_candidates(waid)
    [waid, normalize(waid)].uniq
  end

  def variants(waid)
    normalized = normalize(waid)
    [normalized, legacy_mobile_form(normalized)].compact.uniq
  end

  private

  # Mirror of #normalize: a canonical mobile maps back to its pre-2012 eight-digit form only when
  # what remains is itself a legacy mobile range. Stripping the 9 off any other canonical mobile
  # would yield a landline that belongs to a different subscriber.
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
