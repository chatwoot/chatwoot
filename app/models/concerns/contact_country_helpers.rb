module ContactCountryHelpers
  extend ActiveSupport::Concern

  included do
    validate :validate_country_code, if: :will_save_change_to_country_code?
  end

  def canonical_country_code
    attributes = additional_attributes || {}

    CountryCodeNormalizer.normalize(self[:country_code]) ||
      CountryCodeNormalizer.normalize(attributes['country_code']) ||
      CountryCodeNormalizer.normalize(attributes['country'])
  end

  def canonical_country_name
    CountryCodeNormalizer.name_for(canonical_country_code)
  end

  def additional_attributes_with_canonical_country
    attributes = additional_attributes.deep_dup || {}
    code = canonical_country_code
    return attributes if code.blank?

    attributes.merge(
      'country_code' => code,
      'country' => CountryCodeNormalizer.name_for(code)
    )
  end

  private

  def validate_country_code
    return if country_code.blank? || CountryCodeNormalizer.normalize(country_code)

    errors.add(:country_code, :invalid)
  end
end
