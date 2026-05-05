# frozen_string_literal: true

class Contacts::ReplaceContactPoints
  pattr_initialize [:contact!, :params!]

  def perform
    ActiveRecord::Base.transaction do
      contact.assign_attributes(primary_attributes)
      remove_promoted_contact_points
      contact.save!
      replace_emails
      replace_phones
      contact.reload
    end
  end

  private

  def primary_attributes
    attributes = {}
    attributes[:email] = email_value_for_write if email_payload_provided?
    attributes[:phone_number] = phone_value_for_write if phone_payload_provided?
    attributes
  end

  def replace_emails
    return unless replace_emails?

    contact.contact_emails.destroy_all
    additional_email_values.each do |email|
      contact.contact_emails.create!(account: contact.account, email: email)
    end
  end

  def replace_phones
    return unless replace_phones?

    contact.contact_phones.destroy_all
    additional_phone_values.each do |phone_number|
      contact.contact_phones.create!(account: contact.account, phone_number: phone_number)
    end
  end

  def remove_promoted_contact_points
    remove_promoted_email
    remove_promoted_phone
  end

  def remove_promoted_email
    return unless contact.will_save_change_to_email?

    contact.contact_emails.where(email: normalized_email_value(contact.email)).destroy_all
  end

  def remove_promoted_phone
    return unless contact.will_save_change_to_phone_number?

    contact.contact_phones.where(phone_number: normalized_phone_value(contact.phone_number)).destroy_all
  end

  def email_value_for_write
    explicit_email = normalized_email_value(param_value(:email))
    return explicit_email if explicit_email.present?
    return normalized_email_values(:email_addresses).first if param_provided?(:email_addresses)

    explicit_email
  end

  def phone_value_for_write
    explicit_phone = normalized_phone_value(param_value(:phone_number))
    return explicit_phone if explicit_phone.present?
    return normalized_phone_values(:phone_numbers).first if param_provided?(:phone_numbers)

    explicit_phone
  end

  def additional_email_values
    values = if param_provided?(:additional_emails)
               normalized_email_values(:additional_emails)
             else
               normalized_email_values(:email_addresses)
             end

    values - [normalized_email_value(contact.email)]
  end

  def additional_phone_values
    values = if param_provided?(:additional_phones)
               normalized_phone_values(:additional_phones)
             else
               normalized_phone_values(:phone_numbers)
             end

    values - [normalized_phone_value(contact.phone_number)]
  end

  def normalized_email_values(key)
    normalized_values(key) { |value| normalized_email_value(value) }
  end

  def normalized_phone_values(key)
    normalized_values(key) { |value| normalized_phone_value(value) }
  end

  def normalized_values(key, &)
    return [] if param_value(key) == '[]'

    Array(param_value(key)).filter_map(&).uniq
  end

  def normalized_email_value(value)
    value.to_s.strip.downcase.presence
  end

  def normalized_phone_value(value)
    value.to_s.strip.presence
  end

  def replace_emails?
    param_provided?(:additional_emails) || param_provided?(:email_addresses)
  end

  def replace_phones?
    param_provided?(:additional_phones) || param_provided?(:phone_numbers)
  end

  def email_payload_provided?
    param_provided?(:email) || param_provided?(:email_addresses)
  end

  def phone_payload_provided?
    param_provided?(:phone_number) || param_provided?(:phone_numbers)
  end

  def param_provided?(key)
    params.key?(key) || params.key?(key.to_s)
  end

  def param_value(key)
    params[key] || params[key.to_s]
  end
end
