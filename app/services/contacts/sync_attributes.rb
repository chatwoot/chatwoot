class Contacts::SyncAttributes
  attr_reader :contact

  def initialize(contact)
    @contact = contact
  end

  def perform
    update_contact_location_and_country_code
    set_contact_type
  end

  private

  def update_contact_location_and_country_code
    @contact.location = @contact.additional_attributes['city']
    sync_country_code
  end

  def sync_country_code
    attributes = contact.additional_attributes
    previous_attributes = contact.additional_attributes_in_database || {}
    return sync_root_country(attributes, previous_attributes) if contact.will_save_change_to_country_code?

    changed_key = changed_country_key(attributes, previous_attributes)
    return unless changed_key

    code = CountryCodeNormalizer.normalize(attributes[changed_key])
    contact.country_code = code
    return if code.nil? && attributes[changed_key].present?

    sync_legacy_country(attributes, previous_attributes, code)
  end

  def sync_root_country(attributes, previous_attributes)
    code = CountryCodeNormalizer.normalize(contact.country_code)
    contact.country_code = code
    return sync_legacy_country(attributes, previous_attributes, code) if code.nil?

    # Keep legacy readers and country-name sorting consistent during migration.
    attributes['country_code'] = code
    attributes['country'] = CountryCodeNormalizer.name_for(code)
  end

  def changed_country_key(attributes, previous_attributes)
    changed_keys = %w[country_code country].reject { |key| attributes[key] == previous_attributes[key] }
    changed_keys.find { |key| attributes.key?(key) } || changed_keys.first
  end

  def sync_legacy_country(attributes, previous_attributes, code)
    values = { 'country_code' => code, 'country' => CountryCodeNormalizer.name_for(code) }
    values.each do |key, value|
      attributes[key] = value if attributes.key?(key) || previous_attributes.key?(key)
    end
  end

  def set_contact_type
    #  If the contact is already a lead or customer then do not change the contact type
    return unless @contact.contact_type == 'visitor'
    # A contact with an email, phone number, identifier or social details is a lead
    return unless @contact.email.present? || @contact.phone_number.present? || @contact.identifier.present? || social_details_present?

    @contact.contact_type = 'lead'
  end

  def social_details_present?
    @contact.additional_attributes.keys.any? do |key|
      key.start_with?('social_') && @contact.additional_attributes[key].present?
    end
  end
end
