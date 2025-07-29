class Contacts::SyncAttributes
  attr_reader :contact

  def initialize(contact)
    @contact = contact
  end

  def perform
    update_contact_location_and_country_code
    set_contact_type
  end

  def perform_with_migration
    update_contact_location_and_country_code
    migrate_social_attributes
    set_contact_type
  end

  private

  def update_contact_location_and_country_code
    # Ensure that location and country_code are updated from additional_attributes.
    # TODO: Remove this once all contacts are updated and both the location and country_code fields are standardized throughout the app.
    @contact.location = @contact.additional_attributes['city']
    @contact.country_code = @contact.additional_attributes['country']
  end

  def set_contact_type
    #  If the contact is already a lead or customer then do not change the contact type
    return unless @contact.contact_type == 'visitor'
    # If the contact has an email or phone number or social details( facebook_user_id, instagram_user_id, etc) then it is a lead
    # If contact is from external channel like facebook, instagram, whatsapp, etc then it is a lead
    return unless @contact.email.present? || @contact.phone_number.present? || @contact.identifier.present? || social_details_present?

    @contact.contact_type = 'lead'
  end

  def social_details_present?
    @contact.additional_attributes.keys.any? do |key|
      key.start_with?('social_') && @contact.additional_attributes[key].present?
    end
  end

  def migrate_social_attributes
    return if @contact.additional_attributes.blank?

    attrs = @contact.additional_attributes
    social_profiles = attrs['social_profiles'] || {}

    return if social_profiles.blank?

    # Migrate Telegram - check both social_profiles and legacy username field
    migrate_telegram_attributes(attrs, social_profiles)

    # Migrate Facebook
    migrate_facebook_attributes(attrs, social_profiles)

    # Migrate LINE
    migrate_line_attributes(attrs, social_profiles)
  end

  def migrate_telegram_attributes(attrs, profiles)
    # Previous format
    # {
    #   "social_profiles": {
    #     "telegram": "gilpadraocruz"
    #   }
    # }
    # New format
    # {
    #   "social_telegram_user_name": "gilpadraocruz"
    # }
    telegram_username = profiles['telegram'].presence || attrs['username'].presence
    return if telegram_username.blank?

    attrs['social_telegram_user_name'] ||= telegram_username
  end

  def migrate_facebook_attributes(attrs, profiles)
    # Previous format
    # {
    #   "social_profiles": {
    #     "facebook": "gilpadraocruz"
    #   }
    # }
    # New format
    # {
    #   "social_facebook_user_name": "gilpadraocruz"
    # }
    return if profiles['facebook'].blank?

    attrs['social_facebook_user_name'] ||= profiles['facebook']
  end

  def migrate_line_attributes(attrs, profiles)
    # Previous format
    # {
    #   "social_profiles": {
    #     "line": "gilpadraocruz"
    #   }
    # }
    # New format
    # {
    #   "social_line_user_id": "gilpadraocruz"
    # }
    return if profiles['line'].blank?

    attrs['social_line_user_id'] ||= profiles['line']
  end
end
