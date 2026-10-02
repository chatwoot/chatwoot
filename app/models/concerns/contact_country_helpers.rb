module ContactCountryHelpers
  extend ActiveSupport::Concern

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
      'country' => canonical_country_name || attributes['country']
    )
  end
end
