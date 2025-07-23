class Migration::MigrateAccountContactsJob < ApplicationJob
  queue_as :async_database_migration

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return unless account

    Rails.logger.info "Processing contact migration for account #{account_id} (#{account.name})"

    contacts = account.contacts.where(contact_type: 'visitor')
    processed_count = 0

    contacts.find_each do |contact|
      processed_count += 1 if migrate_contact(contact)
    end

    Rails.logger.info "Processed #{processed_count} contacts for account #{account_id}"
  end

  private

  def migrate_contact(contact)
    return false unless contact.contact_type == 'visitor'

    # Migrate additional_attributes for social cases
    migrate_social_attributes(contact)

    # Determine and update contact type
    new_type = determine_contact_type(contact)
    return false if new_type == 'visitor'

    contact.update!(contact_type: new_type)
    true
  rescue StandardError => e
    Rails.logger.error "Failed to migrate contact #{contact.id}: #{e.message}"
    false
  end

  def migrate_social_attributes(contact)
    additional_attrs = contact.additional_attributes || {}
    social_profiles = additional_attrs['social_profiles'] || {}

    return if social_profiles.blank? || social_profiles == {}

    modified = process_social_platforms(contact, additional_attrs, social_profiles)
    return unless modified

    contact.update!(additional_attributes: additional_attrs)
  end

  def process_social_platforms(contact, attrs, profiles)
    modified = false

    # Telegram - migrate username only (ID comes from service)
    modified ||= migrate_telegram_data(attrs, profiles)

    # Facebook - migrate username only
    modified ||= migrate_facebook_data(attrs, profiles)

    # Instagram - migrate username only
    modified ||= migrate_instagram_data(attrs, profiles)

    # LINE - special case: migrate ID and derive username from contact name
    modified ||= migrate_line_data(contact, attrs, profiles)

    modified
  end

  def migrate_telegram_data(attrs, profiles)
    # Check both social_profiles.telegram and legacy username field
    telegram_username = profiles['telegram'].presence || attrs['username'].presence
    return false if telegram_username.blank?

    attrs['social_telegram_user_name'] ||= telegram_username
    true
  end

  def migrate_facebook_data(attrs, profiles)
    return false if profiles['facebook'].blank?

    attrs['social_facebook_user_name'] ||= profiles['facebook']
    true
  end

  def migrate_instagram_data(attrs, profiles)
    return false if profiles['instagram'].blank?

    attrs['social_instagram_user_name'] ||= profiles['instagram']
    true
  end

  def migrate_line_data(contact, attrs, profiles)
    return false if profiles['line'].blank?

    attrs['social_line_user_id'] ||= profiles['line']
    attrs['social_line_user_name'] ||= contact.name.presence || profiles['line']
    true
  end

  def identification?(contact)
    contact.email.present? || contact.phone_number.present? || contact.identifier.present? || social_details_present?(contact)
  end

  def social_details_present?(contact)
    contact.additional_attributes.keys.any? do |key|
      key.start_with?('social_') && contact.additional_attributes[key].present?
    end
  end

  def determine_contact_type(contact)
    # Visitor: No identification info
    return 'visitor' unless identification?(contact)

    # Lead: Has identification (email, phone, or social details)
    'lead'
  end
end
