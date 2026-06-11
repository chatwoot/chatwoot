module ContactAddressValidatable
  extend ActiveSupport::Concern

  ADDRESS_LENGTH_LIMITS = {
    'address_line_1' => 510,
    'address_line_2' => 510,
    'city' => 200,
    'state' => 200,
    'postal_code' => 40
  }.freeze

  US_POSTAL_CODE_REGEX = /\A\d{5}(-\d{4})?\z/

  included do
    validate :validate_address_attributes
  end

  private

  def validate_address_attributes
    return if additional_attributes.blank?

    validate_address_lengths
    validate_us_postal_code
    validate_us_state
  end

  def validate_address_lengths
    ADDRESS_LENGTH_LIMITS.each do |key, limit|
      value = additional_attributes[key]
      next if value.blank?
      next if value.to_s.length <= limit

      errors.add(:additional_attributes, I18n.t('errors.contacts.address.too_long', field: key, limit: limit))
    end
  end

  def validate_us_postal_code
    return unless us_country?

    postal_code = additional_attributes['postal_code']
    return if postal_code.blank?
    return if postal_code.to_s.match?(US_POSTAL_CODE_REGEX)

    errors.add(:additional_attributes, I18n.t('errors.contacts.address.invalid_us_postal_code'))
  end

  def validate_us_state
    return unless us_country?

    state = additional_attributes['state']
    return if state.blank?
    return if us_state_valid?(state.to_s)

    errors.add(:additional_attributes, I18n.t('errors.contacts.address.invalid_us_state'))
  end

  def us_country?
    additional_attributes['country_code'].to_s.upcase == 'US'
  end

  def us_state_valid?(state)
    normalized = state.strip
    ISO3166::Country.new('US').subdivisions.any? do |code, subdivision|
      code.casecmp?(normalized) || subdivision.name.casecmp?(normalized)
    end
  end
end
