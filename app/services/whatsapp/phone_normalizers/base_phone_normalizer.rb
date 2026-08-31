# Base class for country-specific phone number normalizers
# Each country normalizer should inherit from this class and implement:
# - country_code_pattern: regex to identify the country code
# - normalize: logic to convert phone number to normalized format for contact lookup
# - variants: every equivalent format the same subscriber can arrive in, when the
#   country has more than one (override only if normalize is not reversible)
class Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  def handles_country?(waid)
    waid.match(country_code_pattern)
  end

  def normalize(waid)
    raise NotImplementedError, 'Subclasses must implement #normalize'
  end

  # Equivalent formats to look an existing contact up by, most canonical first
  def variants(waid)
    [normalize(waid)]
  end

  private

  def country_code_pattern
    raise NotImplementedError, 'Subclasses must implement #country_code_pattern'
  end
end
