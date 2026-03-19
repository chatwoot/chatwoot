# frozen_string_literal: true

class Contacts::EmailAddressesSyncService
  UNSET = Object.new

  attr_reader :contact

  def initialize(contact:, email_addresses: UNSET, email: UNSET, touch_parent: true, reload_contact: true)
    @contact = contact
    @email_addresses = email_addresses
    @email = email
    @touch_parent = touch_parent
    @reload_contact = reload_contact
  end

  def perform
    raise ArgumentError, 'contact must be persisted' unless contact.persisted?

    ActiveRecord::Base.transaction do
      if email_addresses_provided?
        sync_email_addresses!
      elsif email_provided?
        sync_legacy_email!
      end
    end

    reload_contact ? contact.reload : contact
  end

  private

  attr_reader :email_addresses, :email, :touch_parent, :reload_contact

  def email_addresses_provided?
    !email_addresses.equal?(UNSET)
  end

  def email_provided?
    !email.equal?(UNSET)
  end

  def sync_email_addresses!
    normalized_rows = normalize_email_addresses(email_addresses)
    validate_email_address_rows!(normalized_rows)

    rows_changed = contact_email_signature != signature_for(normalized_rows)
    cache_changed = update_contact_email_cache!(primary_email_for(normalized_rows))

    replace_contact_emails!(normalized_rows)
    touch_contact_if_needed(rows_changed: rows_changed, cache_changed: cache_changed)
  end

  def sync_legacy_email!
    normalized_email = normalize_email(email)
    existing_signature = contact_email_signature

    if normalized_email.present?
      validate_owned_emails!([normalized_email])
      sync_present_legacy_email!(normalized_email)
    else
      sync_blank_legacy_email!
    end

    touch_contact_if_needed(rows_changed: existing_signature != contact_email_signature, cache_changed: false)
  end

  def sync_present_legacy_email!(normalized_email)
    now = Time.current

    update_contact_email_cache!(normalized_email)
    contact.contact_emails.update_all(primary: false, updated_at: now) # rubocop:disable Rails/SkipsModelValidations

    if contact.contact_emails.exists?(email: normalized_email)
      contact.contact_emails.where(email: normalized_email)
             .update_all(primary: true, updated_at: now) # rubocop:disable Rails/SkipsModelValidations
    else
      contact.contact_emails.create!(account: contact.account, email: normalized_email, primary: true)
    end

    contact.contact_emails.reset
  end

  def sync_blank_legacy_email!
    now = Time.current

    contact.contact_emails.where(primary: true).delete_all
    remaining_emails = contact.contact_emails.order(:created_at, :id)

    if remaining_emails.exists?
      next_primary = remaining_emails.first
      remaining_emails.update_all(primary: false, updated_at: now) # rubocop:disable Rails/SkipsModelValidations
      contact.contact_emails.where(id: next_primary.id)
             .update_all(primary: true, updated_at: now) # rubocop:disable Rails/SkipsModelValidations
      update_contact_email_cache!(next_primary.email)
    else
      update_contact_email_cache!(nil)
    end

    contact.contact_emails.reset
  end

  def replace_contact_emails!(normalized_rows)
    desired_emails = normalized_rows.pluck(:email)
    now = Time.current

    contact.contact_emails.where.not(email: desired_emails).delete_all

    if desired_emails.empty?
      contact.contact_emails.reset
      return
    end

    missing_rows = desired_emails - contact.contact_emails.where(email: desired_emails).pluck(:email)
    insert_missing_contact_emails!(
      normalized_rows.select { |row| missing_rows.include?(row[:email]) },
      primary_email_for(normalized_rows)
    )

    contact.contact_emails.where(email: desired_emails)
           .update_all(primary: false, updated_at: now) # rubocop:disable Rails/SkipsModelValidations
    contact.contact_emails.where(email: primary_email_for(normalized_rows))
           .update_all(primary: true, updated_at: now) # rubocop:disable Rails/SkipsModelValidations
    contact.contact_emails.reset
  end

  def insert_missing_contact_emails!(rows, primary_email)
    return if rows.empty?

    contact_has_primary = contact.contact_emails.exists?(primary: true)

    rows.each do |row|
      contact.contact_emails.create!(
        account: contact.account,
        email: row[:email],
        primary: row[:email] == primary_email && !contact_has_primary
      )
      contact_has_primary ||= row[:email] == primary_email
    end
  end

  def validate_email_address_rows!(normalized_rows)
    invalid_rows = normalized_rows.filter { |row| row[:email].blank? || !row[:email].match?(Devise.email_regexp) }
    contact.errors.add(:email, I18n.t('errors.contacts.email.invalid')) if invalid_rows.present?

    duplicate_rows = normalized_rows.group_by { |row| row[:email] }.select { |_email, rows| rows.size > 1 }
    contact.errors.add(:email, :taken) if duplicate_rows.present?

    primary_count = normalized_rows.count { |row| row[:primary] }
    contact.errors.add(:contact_emails, I18n.t('errors.contacts.email.invalid')) if normalized_rows.present? && primary_count != 1

    validate_owned_emails!(normalized_rows.pluck(:email))
    raise ActiveRecord::RecordInvalid, contact if contact.errors.present?
  end

  def validate_owned_emails!(emails)
    normalized_emails = emails.filter_map { |row_email| normalize_email(row_email) }.uniq
    return if normalized_emails.empty?
    return unless ContactEmail.where(account_id: contact.account_id, email: normalized_emails)
                              .where.not(contact_id: contact.id)
                              .exists?

    contact.errors.add(:email, :taken)
    raise ActiveRecord::RecordInvalid, contact
  end

  def update_contact_email_cache!(value)
    normalized_value = normalize_email(value)
    return false if contact.email == normalized_value

    timestamp = Time.current
    contact.update_columns(email: normalized_value, updated_at: timestamp) # rubocop:disable Rails/SkipsModelValidations
    contact.email = normalized_value
    true
  end

  def touch_contact_if_needed(rows_changed:, cache_changed:)
    return unless touch_parent
    return unless rows_changed
    return if cache_changed || contact.previous_changes.present?

    contact.update!(updated_at: Time.current)
  end

  def normalize_email_addresses(rows)
    Array(rows).map do |row|
      email_value = row.respond_to?(:to_h) ? row.to_h : row

      {
        email: normalize_email(email_value[:email] || email_value['email']),
        primary: ActiveModel::Type::Boolean.new.cast(email_value[:primary].nil? ? email_value['primary'] : email_value[:primary])
      }
    end
  end

  def normalize_email(value)
    value.to_s.strip.downcase.presence
  end

  def primary_email_for(rows)
    rows.find { |row| row[:primary] }&.dig(:email)
  end

  def contact_email_signature
    signature_for(contact.contact_emails.pluck(:email, :primary).map { |row| { email: row[0], primary: row[1] } })
  end

  def signature_for(rows)
    rows.map { |row| [row[:email], row[:primary]] }.sort_by(&:first)
  end
end
